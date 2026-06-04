/**
 * FFWC Proxy Worker
 *
 * Routes:
 *   GET  /matches?date=YYYY-MM-DD     → list WC2026 matches on date (optional)
 *   GET  /matches                     → all WC2026 matches
 *   GET  /lineups/:matchId            → lineups for a match
 *   GET  /health                      → liveness probe
 *
 * All upstream requests authenticated with HL_API_KEY (secret).
 * Responses cached in KV per-URL: matches=5min, lineups=24h.
 */

const CORS = {
  'access-control-allow-origin': '*',
  'access-control-allow-methods': 'GET, OPTIONS',
  'access-control-allow-headers': 'content-type',
};

function json(data, init = {}) {
  return new Response(JSON.stringify(data), {
    ...init,
    headers: {
      'content-type': 'application/json; charset=utf-8',
      'cache-control': 'no-store',
      ...CORS,
      ...(init.headers || {}),
    },
  });
}

function passthrough(body, status, init = {}) {
  return new Response(body, {
    status,
    headers: {
      'content-type': 'application/json; charset=utf-8',
      'cache-control': 'no-store',
      ...CORS,
      ...(init.headers || {}),
    },
  });
}

async function getCached(env, key, ttl, fetcher) {
  const hit = await env.CACHE.get(key);
  if (hit) {
    return { body: hit, status: 200, fromCache: true };
  }
  const result = await fetcher();
  if (result.status === 200) {
    await env.CACHE.put(key, result.body, { expirationTtl: ttl });
  }
  return { ...result, fromCache: false };
}

async function upstreamGet(env, path) {
  const url = `${env.HL_BASE}${path}`;
  const r = await fetch(url, {
    headers: { 'x-rapidapi-key': env.HL_API_KEY },
    cf: { cacheTtl: 0 },
  });
  const body = await r.text();
  return { body, status: r.status };
}

async function fetchAllMatches(env, date) {
  // Upstream caps limit at 100; WC has 104 fixtures, so paginate.
  const all = [];
  let offset = 0;
  let totalCount = 0;
  let planTier = '';
  let lastStatus = 200;
  while (true) {
    const params = new URLSearchParams({
      leagueId: env.WC_LEAGUE_ID,
      season: env.WC_SEASON,
      limit: '100',
      offset: String(offset),
    });
    if (date) params.set('date', date);
    const r = await upstreamGet(env, `/matches?${params.toString()}`);
    lastStatus = r.status;
    if (r.status !== 200) {
      return { body: r.body, status: r.status };
    }
    const j = JSON.parse(r.body);
    const page = j.data || [];
    all.push(...page);
    totalCount = j.pagination?.totalCount ?? page.length;
    planTier = j.plan?.tier || planTier;
    offset += page.length;
    if (offset >= totalCount || page.length === 0) break;
  }
  const merged = {
    data: all,
    plan: { tier: planTier, message: 'aggregated by proxy' },
    pagination: { totalCount, offset: 0, limit: all.length },
  };
  return { body: JSON.stringify(merged), status: lastStatus };
}

async function handleMatches(env, urlObj) {
  const date = urlObj.searchParams.get('date'); // YYYY-MM-DD or null
  const cacheKey = `m:${date || 'all'}`;
  const ttl = parseInt(env.MATCHES_TTL, 10);
  const r = await getCached(env, cacheKey, ttl, () => fetchAllMatches(env, date));
  return passthrough(r.body, r.status, {
    headers: { 'x-cache': r.fromCache ? 'HIT' : 'MISS' },
  });
}

async function handleLineups(env, matchId) {
  if (!/^\d+$/.test(matchId)) {
    return json({ error: 'invalid matchId' }, { status: 400 });
  }
  const path = `/lineups/${matchId}`;
  const cacheKey = `l:${matchId}`;
  const ttl = parseInt(env.LINEUPS_TTL, 10);
  const r = await getCached(env, cacheKey, ttl, () => upstreamGet(env, path));
  return passthrough(r.body, r.status, {
    headers: { 'x-cache': r.fromCache ? 'HIT' : 'MISS' },
  });
}

export default {
  async fetch(request, env, _ctx) {
    if (request.method === 'OPTIONS') {
      return new Response(null, { status: 204, headers: CORS });
    }
    if (request.method !== 'GET') {
      return json({ error: 'method not allowed' }, { status: 405 });
    }
    const u = new URL(request.url);

    try {
      if (u.pathname === '/health') {
        return json({ ok: true, ts: Date.now() });
      }
      if (u.pathname === '/matches') {
        return await handleMatches(env, u);
      }
      const m = u.pathname.match(/^\/lineups\/(\d+)$/);
      if (m) {
        return await handleLineups(env, m[1]);
      }
      return json({ error: 'not found' }, { status: 404 });
    } catch (e) {
      return json({ error: 'internal', message: e.message }, { status: 503 });
    }
  },
};
