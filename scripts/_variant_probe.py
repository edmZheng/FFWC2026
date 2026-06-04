import urllib.request, urllib.parse, json, re
UA = "FFWC-Tracker/1.0 (variant-probe; wc26tracker@gmail.com)"
tests = [
    "基斯坦奴·朗拿度", "卡斯米路", "马昆奴斯",
    "拿达路·马天尼斯", "基利安·麦巴比", "孟菲斯·迪比",
    "利昂内尔·梅西", "维尼修斯·儒尼奥尔", "阿历士·辛度",
    "贝纳尔多·席尔瓦", "巴尔特·费布吕亨", "尼尔逊·施美度",
]
for zh in tests:
    page = urllib.parse.quote(zh.replace(" ", "_"))
    url = (
        f"https://zh.wikipedia.org/w/api.php?action=parse&format=json"
        f"&page={page}&prop=displaytitle&variant=zh-cn&redirects=1"
    )
    try:
        req = urllib.request.Request(url, headers={"User-Agent": UA})
        with urllib.request.urlopen(req, timeout=20) as r:
            data = json.loads(r.read().decode("utf-8"))
        parse = data.get("parse", {})
        t = parse.get("title", "")
        dt = parse.get("displaytitle", "")
        if "<" in dt:
            dt = re.sub(r"<[^>]+>", "", dt)
        ok = "OK" if dt and dt != t else "(no-conv)" if dt == t else "(empty)"
        print(f'  {zh:30s} -> "{dt}"  {ok}')
    except Exception as e:
        print(f"  {zh:30s} ERR: {e}")
