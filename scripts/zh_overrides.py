"""人工核对的大陆约定俗成中文译名（EN → ZH-CN）。

数据来源：以新华社《世界人名翻译大辞典》和 ESPN/腾讯/虎扑等大陆媒体的
长期使用为准。覆盖 2026 世界杯 48 强中最常被讨论的球星 +
Wikipedia 自动转换无法修正的港台音译。
"""

OVERRIDES: dict[str, str] = {
    # Portugal
    "Cristiano Ronaldo": "克里斯蒂亚诺·罗纳尔多",
    "Bernardo Silva": "贝尔纳多·席尔瓦",
    "Bruno Fernandes": "布鲁诺·费尔南德斯",
    "Rúben Dias": "鲁本·迪亚斯",
    "Nélson Semedo": "内尔松·塞梅多",
    "João Cancelo": "若昂·坎塞洛",
    "João Félix": "若昂·菲利克斯",
    "Diogo Costa": "迪奥戈·科斯塔",
    "Vitinha": "维蒂尼亚",
    "Rafael Leão": "拉法埃尔·莱昂",
    "Pepe": "佩佩",
    "Diogo Jota": "迪奥戈·若塔",

    # Argentina
    "Lionel Messi": "莱昂内尔·梅西",
    "Lautaro Martínez": "劳塔罗·马丁内斯",
    "Julián Álvarez": "胡利安·阿尔瓦雷斯",
    "Emiliano Martínez": "埃米利亚诺·马丁内斯",
    "Rodrigo De Paul": "罗德里戈·德保罗",
    "Ángel Di María": "安赫尔·迪马里亚",
    "Nahuel Molina": "纳韦尔·莫利纳",
    "Cristian Romero": "克里斯蒂安·罗梅罗",
    "Nicolás Otamendi": "尼古拉斯·奥塔门迪",
    "Leandro Paredes": "莱安德罗·帕雷德斯",
    "Enzo Fernández": "恩佐·费尔南德斯",
    "Alexis Mac Allister": "亚历克西斯·麦卡利斯特",

    # Brazil
    "Vinícius Júnior": "维尼修斯·儒尼奥尔",
    "Casemiro": "卡塞米罗",
    "Marquinhos": "马尔基尼奥斯",
    "Alex Sandro": "亚历克斯·桑德罗",
    "Alisson": "阿利松",
    "Ederson": "埃德松",
    "Raphinha": "拉菲尼亚",
    "Rodrygo": "罗德里戈",
    "Bruno Guimarães": "布鲁诺·吉马良斯",
    "Lucas Paquetá": "卢卡斯·帕克塔",
    "Endrick": "恩德里克",
    "Antony": "安东尼",
    "Gabriel Jesus": "加布里埃尔·热苏斯",
    "Éder Militão": "埃德尔·米利唐",
    "Gabriel Magalhães": "加布里埃尔·马加良斯",
    "Bremer": "布雷默",
    "Wesley": "韦斯利",

    # France
    "Kylian Mbappé": "基利安·姆巴佩",
    "Antoine Griezmann": "安托万·格列兹曼",
    "Aurélien Tchouaméni": "奥雷利安·楚阿梅尼",
    "Eduardo Camavinga": "爱德华多·卡马文加",
    "William Saliba": "威廉·萨利巴",
    "Ibrahima Konaté": "伊布拉伊马·科纳特",
    "Dayot Upamecano": "达约·于帕梅卡诺",
    "Mike Maignan": "迈克·迈尼昂",
    "Theo Hernández": "特奥·埃尔南德斯",
    "Lucas Hernandez": "卢卡斯·埃尔南德斯",
    "Marcus Thuram": "马库斯·图拉姆",
    "Ousmane Dembélé": "乌斯曼·登贝莱",
    "Randal Kolo Muani": "兰达尔·科洛·穆阿尼",
    "Bradley Barcola": "布拉德利·巴尔科拉",

    # England
    "Harry Kane": "哈里·凯恩",
    "Jude Bellingham": "裘德·贝林厄姆",
    "Phil Foden": "菲尔·福登",
    "Bukayo Saka": "布卡约·萨卡",
    "Marcus Rashford": "马库斯·拉什福德",
    "Jordan Pickford": "乔丹·皮克福德",
    "John Stones": "约翰·斯通斯",
    "Kyle Walker": "凯尔·沃克",
    "Harry Maguire": "哈里·马奎尔",
    "Declan Rice": "德克兰·赖斯",
    "Cole Palmer": "科尔·帕尔默",

    # Spain
    "Pedri": "佩德里",
    "Gavi": "加维",
    "Lamine Yamal": "拉明·亚马尔",
    "Rodri": "罗德里",
    "Álvaro Morata": "阿尔瓦罗·莫拉塔",
    "Dani Olmo": "丹尼·奥尔莫",
    "Marco Asensio": "马尔科·阿森西奥",
    "Dani Carvajal": "丹尼·卡瓦哈尔",
    "Fabián Ruiz": "法比安·鲁伊斯",
    "Mikel Merino": "米克尔·梅里诺",
    "Nico Williams": "尼科·威廉姆斯",
    "Unai Simón": "乌奈·西蒙",

    # Germany
    "Jamal Musiala": "贾马尔·穆夏拉",
    "Florian Wirtz": "弗洛里安·维尔茨",
    "Kai Havertz": "凯·哈弗茨",
    "Joshua Kimmich": "约书亚·基米希",
    "Leon Goretzka": "莱昂·戈雷茨卡",
    "Leroy Sané": "勒罗伊·萨内",
    "Serge Gnabry": "塞尔日·格纳布里",
    "Antonio Rüdiger": "安东尼奥·吕迪格",
    "Manuel Neuer": "曼努埃尔·诺伊尔",
    "Niclas Füllkrug": "尼克拉斯·菲尔克鲁格",

    # Netherlands
    "Memphis Depay": "孟菲斯·德佩",
    "Frenkie de Jong": "弗伦基·德容",
    "Virgil van Dijk": "维吉尔·范戴克",
    "Cody Gakpo": "科迪·哈克波",
    "Matthijs de Ligt": "马泰斯·德里赫特",
    "Xavi Simons": "哈维·西蒙斯",
    "Tijjani Reijnders": "蒂亚尼·赖恩德斯",
    "Jurriën Timber": "尤里恩·廷贝尔",
    "Bart Verbruggen": "巴特·费尔布鲁根",
    "Denzel Dumfries": "登泽尔·邓弗里斯",

    # Belgium
    "Kevin De Bruyne": "凯文·德布劳内",
    "Romelu Lukaku": "罗梅卢·卢卡库",
    "Yannick Carrasco": "亚尼克·卡拉斯科",
    "Leandro Trossard": "莱安德罗·特罗萨德",
    "Youri Tielemans": "尤里·蒂勒曼斯",
    "Jeremy Doku": "热雷米·多库",
    "Thibaut Courtois": "蒂博·库尔图瓦",

    # Croatia
    "Luka Modrić": "卢卡·莫德里奇",
    "Mateo Kovačić": "马特奥·科瓦契奇",
    "Ivan Perišić": "伊万·佩里西奇",
    "Andrej Kramarić": "安德烈·克拉马里奇",
    "Dominik Livaković": "多米尼克·利瓦科维奇",
    "Joško Gvardiol": "约什科·格瓦迪奥尔",

    # Morocco
    "Achraf Hakimi": "阿什拉夫·哈基米",
    "Hakim Ziyech": "哈基姆·齐耶赫",
    "Youssef En-Nesyri": "尤素福·恩内斯里",
    "Noussair Mazraoui": "努赛尔·马兹拉维",
    "Sofyan Amrabat": "索菲安·阿姆拉巴特",
    "Yassine Bounou": "亚辛·布努",

    # Senegal
    "Sadio Mané": "萨迪奥·马内",
    "Kalidou Koulibaly": "卡利杜·库利巴利",
    "Édouard Mendy": "爱德华·门迪",
    "Idrissa Gueye": "伊德里萨·盖耶",

    # Norway / Denmark / Sweden (likely not all in 48 but kept for completeness)
    "Erling Haaland": "埃尔林·哈兰德",
    "Martin Ødegaard": "马丁·厄德高",

    # Mexico / Concacaf
    "Hirving Lozano": "伊尔文·洛萨诺",
    "Edson Álvarez": "埃德松·阿尔瓦雷斯",
    "Raúl Jiménez": "劳尔·希门尼斯",
    "Christian Pulisic": "克里斯蒂安·普利西奇",
    "Weston McKennie": "韦斯顿·麦肯尼",
    "Tyler Adams": "泰勒·亚当斯",
    "Alphonso Davies": "阿方索·戴维斯",

    # Asia
    "Son Heung-min": "孙兴慜",
    "Kim Min-jae": "金玟哉",
    "Lee Kang-in": "李康仁",
    "Wataru Endō": "远藤航",
    "Wataru Endo": "远藤航",
    "Takefusa Kubo": "久保建英",
    "Daichi Kamada": "镰田大地",
    "Mehdi Taremi": "迈赫迪·塔雷米",
    "Sardar Azmoun": "萨达尔·阿兹蒙",
}
