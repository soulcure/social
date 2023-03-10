import 'dart:math';

import 'package:characters/characters.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:im/utils/emo_util.dart';

///准备测试的emoji列表，数量不要太多，否则耗时会很久

String emojiString =
// ignore: missing_whitespace_between_adjacent_strings
    '🏳️ 🏴 🏁 🚩 🏳️‍🌈 🏴‍☠️ 🇦🇫 🇦🇽 🇦🇱 🇩🇿 🇦🇸 🇦🇩 🇦🇴 🇦🇮 🇦🇶 🇦🇬 🇦🇷 🇦🇲 🇦🇼 🇦🇺 🇦🇹 🇦🇿 🇧🇸 🇧🇭 🇧🇩 🇧🇧 🇧🇾 🇧🇪 🇧🇿 🇧🇯 🇧🇲 🇧🇹 🇧🇴 🇧🇦 🇧🇼 🇧🇷 🇮🇴 🇻🇬 🇧🇳 🇧🇬 🇧🇫 🇧🇮 🇰🇭 🇨🇲 🇨🇦 🇮🇨 🇨🇻 🇧🇶 🇰🇾 🇨🇫 🇹🇩 🇨🇱 🇨🇳 🇨🇽 🇨🇨 🇨🇴 🇰🇲 🇨🇬 🇨🇩 🇨🇰 🇨🇷 🇨🇮 🇭🇷 🇨🇺 🇨🇼 🇨🇾 🇨🇿 🇩🇰 🇩🇯 🇩🇲 🇩🇴 🇪🇨 🇪🇬 🇸🇻 🇬🇶 🇪🇷 🇪🇪 🇪🇹 🇪🇺 🇫🇰 🇫🇴 🇫🇯 🇫🇮 🇫🇷 🇬🇫 🇵🇫 🇹🇫 🇬🇦 🇬🇲 🇬🇪 🇩🇪 🇬🇭 🇬🇮 🇬🇷 🇬🇱 🇬🇩 🇬🇵 🇬🇺 🇬🇹 🇬🇬 🇬🇳 🇬🇼 🇬🇾 🇭🇹 🇭🇳 🇭🇰 🇭🇺 🇮🇸 🇮🇳 🇮🇩 🇮🇷 🇮🇶 🇮🇪 🇮🇲 🇮🇱 🇮🇹 🇯🇲 🇯🇵 🎌 🇯🇪 🇯🇴 🇰🇿 🇰🇪 🇰🇮 🇽🇰 🇰🇼 🇰🇬 🇱🇦 🇱🇻 🇱🇧 🇱🇸 🇱🇷 🇱🇾 🇱🇮 🇱🇹 🇱🇺 🇲🇴 🇲🇰 🇲🇬 🇲🇼 🇲🇾 🇲🇻 🇲🇱 🇲🇹 🇲🇭 🇲🇶 🇲🇷 🇲🇺 🇾🇹 🇲🇽 🇫🇲 🇲🇩 🇲🇨 🇲🇳 🇲🇪 🇲🇸 🇲🇦 🇲🇿 🇲🇲 🇳🇦 🇳🇷 🇳🇵 🇳🇱 🇳🇨 🇳🇿 🇳🇮 🇳🇪 🇳🇬 🇳🇺 🇳🇫 🇰🇵 🇲🇵 🇳🇴 🇴🇲 🇵🇰 🇵🇼 🇵🇸 🇵🇦 🇵🇬 🇵🇾 🇵🇪 🇵🇭 🇵🇳 🇵🇱 🇵🇹 🇵🇷 🇶🇦 🇷🇪 🇷🇴 🇷🇺 🇷🇼 🇼🇸 🇸🇲 🇸🇦 🇸🇳 🇷🇸 🇸🇨 🇸🇱 🇸🇬 🇸🇽 🇸🇰 🇸🇮 🇬🇸 🇸🇧 🇸🇴 🇿🇦 🇰🇷 🇸🇸 🇪🇸 🇱🇰 🇧🇱 🇸🇭 🇰🇳 🇱🇨 🇵🇲 🇻🇨 🇸🇩 🇸🇷 🇸🇿 🇸🇪 🇨🇭 🇸🇾 🇹🇼 🇹🇯 🇹🇿 🇹🇭 🇹🇱 🇹🇬 🇹🇰 🇹🇴 🇹🇹 🇹🇳 🇹🇷 🇹🇲 🇹🇨 🇹🇻 🇻🇮 🇺🇬 🇺🇦 🇦🇪 🇬🇧 🏴󠁧󠁢󠁥󠁮󠁧󠁿 🏴󠁧󠁢󠁳󠁣󠁴󠁿 🏴󠁧󠁢󠁷󠁬󠁳󠁿 🇺🇳 🇺🇸 🇺🇾 🇺🇿 🇻🇺 🇻🇦 🇻🇪 🇻🇳 🇼🇫 🇪🇭 🇾🇪 🇿🇲 🇿🇼'
// ignore: missing_whitespace_between_adjacent_strings
    '❤️ 🧡 💛 💚 💙 💜 🖤 🤍 🤎 💔 ❣️ 💕 💞 💓 💗 💖 💘 💝 💟 ☮️ ✝️ ☪️ 🕉 ☸️ ✡️ 🔯 🕎 ☯️ ☦️ 🛐 ⛎ ♈️ ♉️ ♊️ ♋️ ♌️ ♍️ ♎️ ♏️ ♐️ ♑️ ♒️ ♓️ 🆔 ⚛️ 🉑 ☢️ ☣️ 📴 📳 🈶 🈚️ 🈸 🈺 🈷️ ✴️ 🆚 💮 🉐 ㊙️ ㊗️ 🈴 🈵 🈹 🈲 🅰️ 🅱️ 🆎 🆑 🅾️ 🆘 ❌ ⭕️ 🛑 ⛔️ 📛 🚫 💯 💢 ♨️ 🚷 🚯 🚳 🚱 🔞 📵 🚭 ❗️ ❕ ❓ ❔ ‼️ ⁉️ 🔅 🔆 〽️ ⚠️ 🚸 🔱 ⚜️ 🔰 ♻️ ✅ 🈯️ 💹 ❇️ ✳️ ❎ 🌐 💠 Ⓜ️ 🌀 💤 🏧 🚾 ♿️ 🅿️ 🈳 🈂️ 🛂 🛃 🛄 🛅 🚹 🚺 🚼 🚻 🚮 🎦 📶 🈁 🔣 ℹ️ 🔤 🔡 🔠 🆖 🆗 🆙 🆒 🆕 🆓 0️⃣ 1️⃣ 2️⃣ 3️⃣ 4️⃣ 5️⃣ 6️⃣ 7️⃣ 8️⃣ 9️⃣ 🔟 🔢 #️⃣ *️⃣ ⏏️ ▶️ ⏸ ⏯ ⏹ ⏺ ⏭ ⏮ ⏩ ⏪ ⏫ ⏬ ◀️ 🔼 🔽 ➡️ ⬅️ ⬆️ ⬇️ ↗️ ↘️ ↙️ ↖️ ↕️ ↔️ ↪️ ↩️ ⤴️ ⤵️ 🔀 🔁 🔂 🔄 🔃 🎵 🎶 ➕ ➖ ➗ ✖️ ♾ 💲 💱 ™️ ©️ ®️ 〰️ ➰ ➿ 🔚 🔙 🔛 🔝 🔜 ✔️ ☑️ 🔘 🔴 🟠 🟡 🟢 🔵 🟣 ⚫️ ⚪️ 🟤 🔺 🔻 🔸 🔹 🔶 🔷 🔳 🔲 ▪️ ▫️ ◾️ ◽️ ◼️ ◻️ 🟥 🟧 🟨 🟩 🟦 🟪 ⬛️ ⬜️ 🟫 🔈 🔇 🔉 🔊 🔔 🔕 📣 📢 👁‍🗨 💬 💭 🗯 ♠️ ♣️ ♥️ ♦️ 🃏 🎴 🀄️ 🕐 🕑 🕒 🕓 🕔 🕕 🕖 🕗 🕘 🕙 🕚 🕛 🕜 🕝 🕞 🕟 🕠 🕡 🕢 🕣 🕤 🕥 🕦 🕧'
// ignore: missing_whitespace_between_adjacent_strings
    '⌚️ 📱 📲 💻 ⌨️ 🖥 🖨 🖱 🖲 🕹 🗜 💽 💾 💿 📀 📼 📷 📸 📹 🎥 📽 🎞 📞 ☎️ 📟 📠 📺 📻 🎙 🎚 🎛 🧭 ⏱ ⏲ ⏰ 🕰 ⌛️ ⏳ 📡 🔋 🔌 💡 🔦 🕯 🪔 🧯 🛢 💸 💵 💴 💶 💷 💰 💳 💎 ⚖️ 🧰 🔧 🔨 ⚒ 🛠 ⛏ 🔩 ⚙️ 🧱 ⛓ 🧲 🔫 💣 🧨 🪓 🔪 🗡 ⚔️ 🛡 🚬 ⚰️ ⚱️ 🏺 🔮 📿 🧿 💈 ⚗️ 🔭 🔬 🕳 🩹 🩺 💊 💉 🩸 🧬 🦠 🧫 🧪 🌡 🧹 🧺 🧻 🚽 🚰 🚿 🛁 🛀 🧼 🪒 🧽 🧴 🛎 🔑 🗝 🚪 🪑 🛋 🛏 🛌 🧸 🖼 🛍 🛒 🎁 🎈 🎏 🎀 🎊 🎉 🎎 🏮 🎐 🧧 ✉️ 📩 📨 📧 💌 📥 📤 📦 🏷 📪 📫 📬 📭 📮 📯 📜 📃 📄 📑 🧾 📊 📈 📉 🗒 🗓 📆 📅 🗑 📇 🗃 🗳 🗄 📋 📁 📂 🗂 🗞 📰 📓 📔 📒 📕 📗 📘 📙 📚 📖 🔖 🧷 🔗 📎 🖇 📐 📏 🧮 📌 📍 ✂️ 🖊 🖋 ✒️ 🖌 🖍 📝 ✏️ 🔍 🔎 🔏 🔐 🔒 🔓'
// ignore: missing_whitespace_between_adjacent_strings
    '🚗 🚕 🚙 🚌 🚎 🏎 🚓 🚑 🚒 🚐 🚚 🚛 🚜 🦯 🦽 🦼 🛴 🚲 🛵 🏍 🛺 🚨 🚔 🚍 🚘 🚖 🚡 🚠 🚟 🚃 🚋 🚞 🚝 🚄 🚅 🚈 🚂 🚆 🚇 🚊 🚉 ✈️ 🛫 🛬 🛩 💺 🛰 🚀 🛸 🚁 🛶 ⛵️ 🚤 🛥 🛳 ⛴ 🚢 ⚓️ ⛽️ 🚧 🚦 🚥 🚏 🗺 🗿 🗽 🗼 🏰 🏯 🏟 🎡 🎢 🎠 ⛲️ ⛱ 🏖 🏝 🏜 🌋 ⛰ 🏔 🗻 🏕 ⛺️ 🏠 🏡 🏘 🏚 🏗 🏭 🏢 🏬 🏣 🏤 🏥 🏦 🏨 🏪 🏫 🏩 💒 🏛 ⛪️ 🕌 🕍 🛕 🕋 ⛩ 🛤 🛣 🗾 🎑 🏞 🌅 🌄 🌠 🎇 🎆 🌇 🌆 🏙 🌃 🌌 🌉 🌁'
// ignore: missing_whitespace_between_adjacent_strings
    '⚽️ 🏀 🏈 ⚾️ 🥎 🎾 🏐 🏉 🥏 🎱 🪀 🏓 🏸 🏒 🏑 🥍 🏏 🥅 ⛳️ 🪁 🏹 🎣 🤿 🥊 🥋 🎽 🛹 🛷 ⛸ 🥌 🎿 ⛷ 🏂 🪂 🏋️ 🏋️‍♂️ 🏋️‍♀️ 🤼 🤼‍♂️ 🤼‍♀️ 🤸‍♀️ 🤸 🤸‍♂️ ⛹️ ⛹️‍♂️ ⛹️‍♀️ 🤺 🤾 🤾‍♂️ 🤾‍♀️ 🏌️ 🏌️‍♂️ 🏌️‍♀️ 🏇 🧘 🧘‍♂️ 🧘‍♀️ 🏄 🏄‍♂️ 🏄‍♀️ 🏊 🏊‍♂️ 🏊‍♀️ 🤽 🤽‍♂️ 🤽‍♀️ 🚣 🚣‍♂️ 🚣‍♀️ 🧗 🧗‍♂️ 🧗‍♀️ 🚵 🚵‍♂️ 🚵‍♀️ 🚴 🚴‍♂️ 🚴‍♀️ 🏆 🥇 🥈 🥉 🏅 🎖 🏵 🎗 🎫 🎟 🎪 🤹 🤹‍♂️ 🤹‍♀️ 🎭 🩰 🎨 🎬 🎤 🎧 🎼 🎹 🥁 🎷 🎺 🎸 🪕 🎻 🎲 ♟ 🎯 🎳 🎮 🎰 🧩'
// ignore: missing_whitespace_between_adjacent_strings
    '🍏 🍎 🍐 🍊 🍋 🍌 🍉 🍇 🍓 🍈 🍒 🍑 🥭 🍍 🥥 🥝 🍅 🍆 🥑 🥦 🥬 🥒 🌶 🌽 🥕 🧄 🧅 🥔 🍠 🥐 🥯 🍞 🥖 🥨 🧀 🥚 🍳 🧈 🥞 🧇 🥓 🥩 🍗 🍖 🦴 🌭 🍔 🍟 🍕 🥪 🥙 🧆 🌮 🌯 🥗 🥘 🥫 🍝 🍜 🍲 🍛 🍣 🍱 🥟 🦪 🍤 🍙 🍚 🍘 🍥 🥠 🥮 🍢 🍡 🍧 🍨 🍦 🥧 🧁 🍰 🎂 🍮 🍭 🍬 🍫 🍿 🍩 🍪 🌰 🥜 🍯 🥛 🍼 ☕️ 🍵 🧃 🥤 🍶 🍺 🍻 🥂 🍷 🥃 🍸 🍹 🧉 🍾 🧊 🥄 🍴 🍽 🥣 🥡 🥢 🧂'
// ignore: missing_whitespace_between_adjacent_strings
    '🐶 🐱 🐭 🐹 🐰 🦊 🐻 🐼 🐨 🐯 🦁 🐮 🐷 🐽 🐸 🐵 🙈 🙉 🙊 🐒 🐔 🐧 🐦 🐤 🐣 🐥 🦆 🦅 🦉 🦇 🐺 🐗 🐴 🦄 🐝 🐛 🦋 🐌 🐞 🐜 🦟 🦗 🕷 🕸 🦂 🐢 🐍 🦎 🦖 🦕 🐙 🦑 🦐 🦞 🦀 🐡 🐠 🐟 🐬 🐳 🐋 🦈 🐊 🐅 🐆 🦓 🦍 🦧 🐘 🦛 🦏 🐪 🐫 🦒 🦘 🐃 🐂 🐄 🐎 🐖 🐏 🐑 🦙 🐐 🦌 🐕 🐩 🦮 🐕‍🦺 🐈 🐓 🦃 🦚 🦜 🦢 🦩 🕊 🐇 🦝 🦨 🦡 🦦 🦥 🐁 🐀 🐿 🦔 🐾 🐉 🐲 🌵 🎄 🌲 🌳 🌴 🌱 🌿 ☘️ 🍀 🎍 🎋 🍃 🍂 🍁 🍄 🐚 🌾 💐 🌷 🌹 🥀 🌺 🌸 🌼 🌻 🌞 🌝 🌛 🌜 🌚 🌕 🌖 🌗 🌘 🌑 🌒 🌓 🌔 🌙 🌎 🌍 🌏 🪐 💫 ⭐️ 🌟 ✨ ⚡️ ☄️ 💥 🔥 🌪 🌈 ☀️ 🌤 ⛅️ 🌥 ☁️ 🌦 🌧 ⛈ 🌩 🌨 ❄️ ☃️ ⛄️ 🌬 💨 💧 💦 ☔️ ☂️ 🌊 🌫'
// ignore: missing_whitespace_between_adjacent_strings
    '👋🏿 🤚🏿 🖐🏿 ✋🏿 🖖🏿 👌🏿 🤏🏿 ✌🏿 🤞🏿 🤟🏿 🤘🏿 🤙🏿 👈🏿 👉🏿 👆🏿 🖕🏿 👇🏿 ☝🏿 👍🏿 👎🏿 ✊🏿 👊🏿 🤛🏿 🤜🏿 👏🏿 🙌🏿 👐🏿 🤲🏿 🙏🏿 ✍🏿 💅🏿 🤳🏿 💪🏿 🦵🏿 🦶🏿 👂🏿 🦻🏿 👃🏿 👶🏿 🧒🏿 👦🏿 👧🏿 🧑🏿 👨🏿 👩🏿 🧑🏿‍🦱 👨🏿‍🦱 👩🏿‍🦱 🧑🏿‍🦰 👨🏿‍🦰 👩🏿‍🦰 👱🏿 👱🏿‍♂️ 👱🏿‍♀️ 🧑🏿‍🦳 👨🏿‍🦳 👩🏿‍🦳 🧑🏿‍🦲 👨🏿‍🦲 👩🏿‍🦲 🧔🏿 🧓🏿 👴🏿 👵🏿 🙍🏿 🙍🏿‍♂️ 🙍🏿‍♀️ 🙎🏿 🙎🏿‍♂️ 🙎🏿‍♀️ 🙅🏿 🙅🏿‍♂️ 🙅🏿‍♀️ 🙆🏿 🙆🏿‍♂️ 🙆🏿‍♀️ 💁🏿 💁🏿‍♂️ 💁🏿‍♀️ 🙋🏿 🙋🏿‍♂️ 🙋🏿‍♀️ 🧏🏿 🧏🏿‍♂️ 🧏🏿‍♀️ 🙇🏿 🙇🏿‍♂️ 🙇🏿‍♀️ 🤦🏿 🤦🏿‍♂️ 🤦🏿‍♀️ 🤷🏿 🤷🏿‍♂️ 🤷🏿‍♀️ 🧑🏿‍⚕️ 👨🏿‍⚕️ 👩🏿‍⚕️ 🧑🏿‍🎓 👨🏿‍🎓 👩🏿‍🎓 🧑🏿‍🏫 👨🏿‍🏫 👩🏿‍🏫 🧑🏿‍⚖️ 👨🏿‍⚖️ 👩🏿‍⚖️ 🧑🏿‍🌾 👨🏿‍🌾 👩🏿‍🌾 🧑🏿‍🍳 👨🏿‍🍳 👩🏿‍🍳 🧑🏿‍🔧 👨🏿‍🔧 👩🏿‍🔧 🧑🏿‍🏭 👨🏿‍🏭 👩🏿‍🏭 🧑🏿‍💼 👨🏿‍💼 👩🏿‍💼 🧑🏿‍🔬 👨🏿‍🔬 👩🏿‍🔬 🧑🏿‍💻 👨🏿‍💻 👩🏿‍💻 🧑🏿‍🎤 👨🏿‍🎤 👩🏿‍🎤 🧑🏿‍🎨 👨🏿‍🎨 👩🏿‍🎨 🧑🏿‍✈️ 👨🏿‍✈️ 👩🏿‍✈️ 🧑🏿‍🚀 👨🏿‍🚀 👩🏿‍🚀 🧑🏿‍🚒 👨🏿‍🚒 👩🏿‍🚒 👮🏿 👮🏿‍♂️ 👮🏿‍♀️ 🕵🏿 🕵🏿‍♂️ 🕵🏿‍♀️ 💂🏿 💂🏿‍♂️ 💂🏿‍♀️ 👷🏿 👷🏿‍♂️ 👷🏿‍♀️ 🤴🏿 👸🏿 👳🏿 👳🏿‍♂️ 👳🏿‍♀️ 👲🏿 🧕🏿 🤵🏿 👰🏿 🤰🏿 🤱🏿 👼🏿 🎅🏿 🤶🏿 🦸🏿 🦸🏿‍♂️ 🦸🏿‍♀️ 🦹🏿 🦹🏿‍♂️ 🦹🏿‍♀️ 🧙🏿 🧙🏿‍♂️ 🧙🏿‍♀️ 🧚🏿 🧚🏿‍♂️ 🧚🏿‍♀️ 🧛🏿 🧛🏿‍♂️ 🧛🏿‍♀️ 🧜🏿 🧜🏿‍♂️ 🧜🏿‍♀️ 🧝🏿 🧝🏿‍♂️ 🧝🏿‍♀️ 💆🏿 💆🏿‍♂️ 💆🏿‍♀️ 💇🏿 💇🏿‍♂️ 💇🏿‍♀️ 🚶🏿 🚶🏿‍♂️ 🚶🏿‍♀️ 🧍🏿 🧍🏿‍♂️ 🧍🏿‍♀️ 🧎🏿 🧎🏿‍♂️ 🧎🏿‍♀️ 🧑🏿‍🦯 👨🏿‍🦯 👩🏿‍🦯 🧑🏿‍🦼 👨🏿‍🦼 👩🏿‍🦼 🧑🏿‍🦽 👨🏿‍🦽 👩🏿‍🦽 🏃🏿 🏃🏿‍♂️ 🏃🏿‍♀️ 💃🏿 🕺🏿 🕴🏿 🧖🏿 🧖🏿‍♂️ 🧖🏿‍♀️ 🧗🏿 🧗🏿‍♂️ 🧗🏿‍♀️ 🏇🏿 🏂🏿 🏌🏿 🏌🏿‍♂️ 🏌🏿‍♀️ 🏄🏿 🏄🏿‍♂️ 🏄🏿‍♀️ 🚣🏿 🚣🏿‍♂️ 🚣🏿‍♀️ 🏊🏿 🏊🏿‍♂️ 🏊🏿‍♀️ ⛹🏿 ⛹🏿‍♂️ ⛹🏿‍♀️ 🏋🏿 🏋🏿‍♂️ 🏋🏿‍♀️ 🚴🏿 🚴🏿‍♂️ 🚴🏿‍♀️ 🚵🏿 🚵🏿‍♂️ 🚵🏿‍♀️ 🤸🏿 🤸🏿‍♂️ 🤸🏿‍♀️ 🤽🏿 🤽🏿‍♂️ 🤽🏿‍♀️ 🤾🏿 🤾🏿‍♂️ 🤾🏿‍♀️ 🤹🏿 🤹🏿‍♂️ 🤹🏿‍♀️ 🧘🏿 🧘🏿‍♂️ 🧘🏿‍♀️ 🛀🏿 🛌🏿 🧑🏿‍🤝‍🧑🏿 👬🏿 👭🏿 👫🏿'
// ignore: missing_whitespace_between_adjacent_strings
    '👋🏾 🤚🏾 🖐🏾 ✋🏾 🖖🏾 👌🏾 🤏🏾 ✌🏾 🤞🏾 🤟🏾 🤘🏾 🤙🏾 👈🏾 👉🏾 👆🏾 🖕🏾 👇🏾 ☝🏾 👍🏾 👎🏾 ✊🏾 👊🏾 🤛🏾 🤜🏾 👏🏾 🙌🏾 👐🏾 🤲🏾 🙏🏾 ✍🏾 💅🏾 🤳🏾 💪🏾 🦵🏾 🦶🏾 👂🏾 🦻🏾 👃🏾 👶🏾 🧒🏾 👦🏾 👧🏾 🧑🏾 👨🏾 👩🏾 🧑🏾‍🦱 👨🏾‍🦱 👩🏾‍🦱 🧑🏾‍🦰 👨🏾‍🦰 👩🏾‍🦰 👱🏾 👱🏾‍♂️ 👱🏾‍♀️ 🧑🏾‍🦳 👨🏾‍🦳 👩🏾‍🦳 🧑🏾‍🦲 👨🏾‍🦲 👩🏾‍🦲 🧔🏾 🧓🏾 👴🏾 👵🏾 🙍🏾 🙍🏾‍♂️ 🙍🏾‍♀️ 🙎🏾 🙎🏾‍♂️ 🙎🏾‍♀️ 🙅🏾 🙅🏾‍♂️ 🙅🏾‍♀️ 🙆🏾 🙆🏾‍♂️ 🙆🏾‍♀️ 💁🏾 💁🏾‍♂️ 💁🏾‍♀️ 🙋🏾 🙋🏾‍♂️ 🙋🏾‍♀️ 🧏🏾 🧏🏾‍♂️ 🧏🏾‍♀️ 🙇🏾 🙇🏾‍♂️ 🙇🏾‍♀️ 🤦🏾 🤦🏾‍♂️ 🤦🏾‍♀️ 🤷🏾 🤷🏾‍♂️ 🤷🏾‍♀️ 🧑🏾‍⚕️ 👨🏾‍⚕️ 👩🏾‍⚕️ 🧑🏾‍🎓 👨🏾‍🎓 👩🏾‍🎓 🧑🏾‍🏫 👨🏾‍🏫 👩🏾‍🏫 🧑🏾‍⚖️ 👨🏾‍⚖️ 👩🏾‍⚖️ 🧑🏾‍🌾 👨🏾‍🌾 👩🏾‍🌾 🧑🏾‍🍳 👨🏾‍🍳 👩🏾‍🍳 🧑🏾‍🔧 👨🏾‍🔧 👩🏾‍🔧 🧑🏾‍🏭 👨🏾‍🏭 👩🏾‍🏭 🧑🏾‍💼 👨🏾‍💼 👩🏾‍💼 🧑🏾‍🔬 👨🏾‍🔬 👩🏾‍🔬 🧑🏾‍💻 👨🏾‍💻 👩🏾‍💻 🧑🏾‍🎤 👨🏾‍🎤 👩🏾‍🎤 🧑🏾‍🎨 👨🏾‍🎨 👩🏾‍🎨 🧑🏾‍✈️ 👨🏾‍✈️ 👩🏾‍✈️ 🧑🏾‍🚀 👨🏾‍🚀 👩🏾‍🚀 🧑🏾‍🚒 👨🏾‍🚒 👩🏾‍🚒 👮🏾 👮🏾‍♂️ 👮🏾‍♀️ 🕵🏾 🕵🏾‍♂️ 🕵🏾‍♀️ 💂🏾 💂🏾‍♂️ 💂🏾‍♀️ 👷🏾 👷🏾‍♂️ 👷🏾‍♀️ 🤴🏾 👸🏾 👳🏾 👳🏾‍♂️ 👳🏾‍♀️ 👲🏾 🧕🏾 🤵🏾 👰🏾 🤰🏾 🤱🏾 👼🏾 🎅🏾 🤶🏾 🦸🏾 🦸🏾‍♂️ 🦸🏾‍♀️ 🦹🏾 🦹🏾‍♂️ 🦹🏾‍♀️ 🧙🏾 🧙🏾‍♂️ 🧙🏾‍♀️ 🧚🏾 🧚🏾‍♂️ 🧚🏾‍♀️ 🧛🏾 🧛🏾‍♂️ 🧛🏾‍♀️ 🧜🏾 🧜🏾‍♂️ 🧜🏾‍♀️ 🧝🏾 🧝🏾‍♂️ 🧝🏾‍♀️ 💆🏾 💆🏾‍♂️ 💆🏾‍♀️ 💇🏾 💇🏾‍♂️ 💇🏾‍♀️ 🚶🏾 🚶🏾‍♂️ 🚶🏾‍♀️ 🧍🏾 🧍🏾‍♂️ 🧍🏾‍♀️ 🧎🏾 🧎🏾‍♂️ 🧎🏾‍♀️ 🧑🏾‍🦯 👨🏾‍🦯 👩🏾‍🦯 🧑🏾‍🦼 👨🏾‍🦼 👩🏾‍🦼 🧑🏾‍🦽 👨🏾‍🦽 👩🏾‍🦽 🏃🏾 🏃🏾‍♂️ 🏃🏾‍♀️ 💃🏾 🕺🏾 🕴🏾 🧖🏾 🧖🏾‍♂️ 🧖🏾‍♀️ 🧗🏾 🧗🏾‍♂️ 🧗🏾‍♀️ 🏇🏾 🏂🏾 🏌🏾 🏌🏾‍♂️ 🏌🏾‍♀️ 🏄🏾 🏄🏾‍♂️ 🏄🏾‍♀️ 🚣🏾 🚣🏾‍♂️ 🚣🏾‍♀️ 🏊🏾 🏊🏾‍♂️ 🏊🏾‍♀️ ⛹🏾 ⛹🏾‍♂️ ⛹🏾‍♀️ 🏋🏾 🏋🏾‍♂️ 🏋🏾‍♀️ 🚴🏾 🚴🏾‍♂️ 🚴🏾‍♀️ 🚵🏾 🚵🏾‍♂️ 🚵🏾‍♀️ 🤸🏾 🤸🏾‍♂️ 🤸🏾‍♀️ 🤽🏾 🤽🏾‍♂️ 🤽🏾‍♀️ 🤾🏾 🤾🏾‍♂️ 🤾🏾‍♀️ 🤹🏾 🤹🏾‍♂️ 🤹🏾‍♀️ 🧘🏾 🧘🏾‍♂️ 🧘🏾‍♀️ 🛀🏾 🛌🏾 🧑🏾‍🤝‍🧑🏾 👬🏾 👭🏾 👫🏾'
// ignore: missing_whitespace_between_adjacent_strings
    '👋🏽 🤚🏽 🖐🏽 ✋🏽 🖖🏽 👌🏽 🤏🏽 ✌🏽 🤞🏽 🤟🏽 🤘🏽 🤙🏽 👈🏽 👉🏽 👆🏽 🖕🏽 👇🏽 ☝🏽 👍🏽 👎🏽 ✊🏽 👊🏽 🤛🏽 🤜🏽 👏🏽 🙌🏽 👐🏽 🤲🏽 🙏🏽 ✍🏽 💅🏽 🤳🏽 💪🏽 🦵🏽 🦶🏽 👂🏽 🦻🏽 👃🏽 👶🏽 🧒🏽 👦🏽 👧🏽 🧑🏽 👨🏽 👩🏽 🧑🏽‍🦱 👨🏽‍🦱 👩🏽‍🦱 🧑🏽‍🦰 👨🏽‍🦰 👩🏽‍🦰 👱🏽 👱🏽‍♂️ 👱🏽‍♀️ 🧑🏽‍🦳 👨🏽‍🦳 👩🏽‍🦳 🧑🏽‍🦲 👨🏽‍🦲 👩🏽‍🦲 🧔🏽 🧓🏽 👴🏽 👵🏽 🙍🏽 🙍🏽‍♂️ 🙍🏽‍♀️ 🙎🏽 🙎🏽‍♂️ 🙎🏽‍♀️ 🙅🏽 🙅🏽‍♂️ 🙅🏽‍♀️ 🙆🏽 🙆🏽‍♂️ 🙆🏽‍♀️ 💁🏽 💁🏽‍♂️ 💁🏽‍♀️ 🙋🏽 🙋🏽‍♂️ 🙋🏽‍♀️ 🧏🏽 🧏🏽‍♂️ 🧏🏽‍♀️ 🙇🏽 🙇🏽‍♂️ 🙇🏽‍♀️ 🤦🏽 🤦🏽‍♂️ 🤦🏽‍♀️ 🤷🏽 🤷🏽‍♂️ 🤷🏽‍♀️ 🧑🏽‍⚕️ 👨🏽‍⚕️ 👩🏽‍⚕️ 🧑🏽‍🎓 👨🏽‍🎓 👩🏽‍🎓 🧑🏽‍🏫 👨🏽‍🏫 👩🏽‍🏫 🧑🏽‍⚖️ 👨🏽‍⚖️ 👩🏽‍⚖️ 🧑🏽‍🌾 👨🏽‍🌾 👩🏽‍🌾 🧑🏽‍🍳 👨🏽‍🍳 👩🏽‍🍳 🧑🏽‍🔧 👨🏽‍🔧 👩🏽‍🔧 🧑🏽‍🏭 👨🏽‍🏭 👩🏽‍🏭 🧑🏽‍💼 👨🏽‍💼 👩🏽‍💼 🧑🏽‍🔬 👨🏽‍🔬 👩🏽‍🔬 🧑🏽‍💻 👨🏽‍💻 👩🏽‍💻 🧑🏽‍🎤 👨🏽‍🎤 👩🏽‍🎤 🧑🏽‍🎨 👨🏽‍🎨 👩🏽‍🎨 🧑🏽‍✈️ 👨🏽‍✈️ 👩🏽‍✈️ 🧑🏽‍🚀 👨🏽‍🚀 👩🏽‍🚀 🧑🏽‍🚒 👨🏽‍🚒 👩🏽‍🚒 👮🏽 👮🏽‍♂️ 👮🏽‍♀️ 🕵🏽 🕵🏽‍♂️ 🕵🏽‍♀️ 💂🏽 💂🏽‍♂️ 💂🏽‍♀️ 👷🏽 👷🏽‍♂️ 👷🏽‍♀️ 🤴🏽 👸🏽 👳🏽 👳🏽‍♂️ 👳🏽‍♀️ 👲🏽 🧕🏽 🤵🏽 👰🏽 🤰🏽 🤱🏽 👼🏽 🎅🏽 🤶🏽 🦸🏽 🦸🏽‍♂️ 🦸🏽‍♀️ 🦹🏽 🦹🏽‍♂️ 🦹🏽‍♀️ 🧙🏽 🧙🏽‍♂️ 🧙🏽‍♀️ 🧚🏽 🧚🏽‍♂️ 🧚🏽‍♀️ 🧛🏽 🧛🏽‍♂️ 🧛🏽‍♀️ 🧜🏽 🧜🏽‍♂️ 🧜🏽‍♀️ 🧝🏽 🧝🏽‍♂️ 🧝🏽‍♀️ 💆🏽 💆🏽‍♂️ 💆🏽‍♀️ 💇🏽 💇🏽‍♂️ 💇🏽‍♀️ 🚶🏽 🚶🏽‍♂️ 🚶🏽‍♀️ 🧍🏽 🧍🏽‍♂️ 🧍🏽‍♀️ 🧎🏽 🧎🏽‍♂️ 🧎🏽‍♀️ 🧑🏽‍🦯 👨🏽‍🦯 👩🏽‍🦯 🧑🏽‍🦼 👨🏽‍🦼 👩🏽‍🦼 🧑🏽‍🦽 👨🏽‍🦽 👩🏽‍🦽 🏃🏽 🏃🏽‍♂️ 🏃🏽‍♀️ 💃🏽 🕺🏽 🕴🏽 🧖🏽 🧖🏽‍♂️ 🧖🏽‍♀️ 🧗🏽 🧗🏽‍♂️ 🧗🏽‍♀️ 🏇🏽 🏂🏽 🏌🏽 🏌🏽‍♂️ 🏌🏽‍♀️ 🏄🏽 🏄🏽‍♂️ 🏄🏽‍♀️ 🚣🏽 🚣🏽‍♂️ 🚣🏽‍♀️ 🏊🏽 🏊🏽‍♂️ 🏊🏽‍♀️ ⛹🏽 ⛹🏽‍♂️ ⛹🏽‍♀️ 🏋🏽 🏋🏽‍♂️ 🏋🏽‍♀️ 🚴🏽 🚴🏽‍♂️ 🚴🏽‍♀️ 🚵🏽 🚵🏽‍♂️ 🚵🏽‍♀️ 🤸🏽 🤸🏽‍♂️ 🤸🏽‍♀️ 🤽🏽 🤽🏽‍♂️ 🤽🏽‍♀️ 🤾🏽 🤾🏽‍♂️ 🤾🏽‍♀️ 🤹🏽 🤹🏽‍♂️ 🤹🏽‍♀️ 🧘🏽 🧘🏽‍♂️ 🧘🏽‍♀️ 🛀🏽 🛌🏽 🧑🏽‍🤝‍🧑🏽 👬🏽 👭🏽 👫🏽'
// ignore: missing_whitespace_between_adjacent_strings
    '👋🏼 🤚🏼 🖐🏼 ✋🏼 🖖🏼 👌🏼 🤏🏼 ✌🏼 🤞🏼 🤟🏼 🤘🏼 🤙🏼 👈🏼 👉🏼 👆🏼 🖕🏼 👇🏼 ☝🏼 👍🏼 👎🏼 ✊🏼 👊🏼 🤛🏼 🤜🏼 👏🏼 🙌🏼 👐🏼 🤲🏼 🙏🏼 ✍🏼 💅🏼 🤳🏼 💪🏼 🦵🏼 🦶🏼 👂🏼 🦻🏼 👃🏼 👶🏼 🧒🏼 👦🏼 👧🏼 🧑🏼 👨🏼 👩🏼 🧑🏼‍🦱 👨🏼‍🦱 👩🏼‍🦱 🧑🏼‍🦰 👨🏼‍🦰 👩🏼‍🦰 👱🏼 👱🏼‍♂️ 👱🏼‍♀️ 🧑🏼‍🦳 👨🏼‍🦳 👩🏼‍🦳 🧑🏼‍🦲 👨🏼‍🦲 👩🏼‍🦲 🧔🏼 🧓🏼 👴🏼 👵🏼 🙍🏼 🙍🏼‍♂️ 🙍🏼‍♀️ 🙎🏼 🙎🏼‍♂️ 🙎🏼‍♀️ 🙅🏼 🙅🏼‍♂️ 🙅🏼‍♀️ 🙆🏼 🙆🏼‍♂️ 🙆🏼‍♀️ 💁🏼 💁🏼‍♂️ 💁🏼‍♀️ 🙋🏼 🙋🏼‍♂️ 🙋🏼‍♀️ 🧏🏼 🧏🏼‍♂️ 🧏🏼‍♀️ 🙇🏼 🙇🏼‍♂️ 🙇🏼‍♀️ 🤦🏼 🤦🏼‍♂️ 🤦🏼‍♀️ 🤷🏼 🤷🏼‍♂️ 🤷🏼‍♀️ 🧑🏼‍⚕️ 👨🏼‍⚕️ 👩🏼‍⚕️ 🧑🏼‍🎓 👨🏼‍🎓 👩🏼‍🎓 🧑🏼‍🏫 👨🏼‍🏫 👩🏼‍🏫 🧑🏼‍⚖️ 👨🏼‍⚖️ 👩🏼‍⚖️ 🧑🏼‍🌾 👨🏼‍🌾 👩🏼‍🌾 🧑🏼‍🍳 👨🏼‍🍳 👩🏼‍🍳 🧑🏼‍🔧 👨🏼‍🔧 👩🏼‍🔧 🧑🏼‍🏭 👨🏼‍🏭 👩🏼‍🏭 🧑🏼‍💼 👨🏼‍💼 👩🏼‍💼 🧑🏼‍🔬 👨🏼‍🔬 👩🏼‍🔬 🧑🏼‍💻 👨🏼‍💻 👩🏼‍💻 🧑🏼‍🎤 👨🏼‍🎤 👩🏼‍🎤 🧑🏼‍🎨 👨🏼‍🎨 👩🏼‍🎨 🧑🏼‍✈️ 👨🏼‍✈️ 👩🏼‍✈️ 🧑🏼‍🚀 👨🏼‍🚀 👩🏼‍🚀 🧑🏼‍🚒 👨🏼‍🚒 👩🏼‍🚒 👮🏼 👮🏼‍♂️ 👮🏼‍♀️ 🕵🏼 🕵🏼‍♂️ 🕵🏼‍♀️ 💂🏼 💂🏼‍♂️ 💂🏼‍♀️ 👷🏼 👷🏼‍♂️ 👷🏼‍♀️ 🤴🏼 👸🏼 👳🏼 👳🏼‍♂️ 👳🏼‍♀️ 👲🏼 🧕🏼 🤵🏼 👰🏼 🤰🏼 🤱🏼 👼🏼 🎅🏼 🤶🏼 🦸🏼 🦸🏼‍♂️ 🦸🏼‍♀️ 🦹🏼 🦹🏼‍♂️ 🦹🏼‍♀️ 🧙🏼 🧙🏼‍♂️ 🧙🏼‍♀️ 🧚🏼 🧚🏼‍♂️ 🧚🏼‍♀️ 🧛🏼 🧛🏼‍♂️ 🧛🏼‍♀️ 🧜🏼 🧜🏼‍♂️ 🧜🏼‍♀️ 🧝🏼 🧝🏼‍♂️ 🧝🏼‍♀️ 💆🏼 💆🏼‍♂️ 💆🏼‍♀️ 💇🏼 💇🏼‍♂️ 💇🏼‍♀️ 🚶🏼 🚶🏼‍♂️ 🚶🏼‍♀️ 🧍🏼 🧍🏼‍♂️ 🧍🏼‍♀️ 🧎🏼 🧎🏼‍♂️ 🧎🏼‍♀️ 🧑🏼‍🦯 👨🏼‍🦯 👩🏼‍🦯 🧑🏼‍🦼 👨🏼‍🦼 👩🏼‍🦼 🧑🏼‍🦽 👨🏼‍🦽 👩🏼‍🦽 🏃🏼 🏃🏼‍♂️ 🏃🏼‍♀️ 💃🏼 🕺🏼 🕴🏼 🧖🏼 🧖🏼‍♂️ 🧖🏼‍♀️ 🧗🏼 🧗🏼‍♂️ 🧗🏼‍♀️ 🏇🏼 🏂🏼 🏌🏼 🏌🏼‍♂️ 🏌🏼‍♀️ 🏄🏼 🏄🏼‍♂️ 🏄🏼‍♀️ 🚣🏼 🚣🏼‍♂️ 🚣🏼‍♀️ 🏊🏼 🏊🏼‍♂️ 🏊🏼‍♀️ ⛹🏼 ⛹🏼‍♂️ ⛹🏼‍♀️ 🏋🏼 🏋🏼‍♂️ 🏋🏼‍♀️ 🚴🏼 🚴🏼‍♂️ 🚴🏼‍♀️ 🚵🏼 🚵🏼‍♂️ 🚵🏼‍♀️ 🤸🏼 🤸🏼‍♂️ 🤸🏼‍♀️ 🤽🏼 🤽🏼‍♂️ 🤽🏼‍♀️ 🤾🏼 🤾🏼‍♂️ 🤾🏼‍♀️ 🤹🏼 🤹🏼‍♂️ 🤹🏼‍♀️ 🧘🏼 🧘🏼‍♂️ 🧘🏼‍♀️ 🛀🏼 🛌🏼 🧑🏼‍🤝‍🧑🏼 👬🏼 👭🏼 👫🏼'
// ignore: missing_whitespace_between_adjacent_strings
    '👋🏻 🤚🏻 🖐🏻 ✋🏻 🖖🏻 👌🏻 🤏🏻 ✌🏻 🤞🏻 🤟🏻 🤘🏻 🤙🏻 👈🏻 👉🏻 👆🏻 🖕🏻 👇🏻 ☝🏻 👍🏻 👎🏻 ✊🏻 👊🏻 🤛🏻 🤜🏻 👏🏻 🙌🏻 👐🏻 🤲🏻 🙏🏻 ✍🏻 💅🏻 🤳🏻 💪🏻 🦵🏻 🦶🏻 👂🏻 🦻🏻 👃🏻 👶🏻 🧒🏻 👦🏻 👧🏻 🧑🏻 👨🏻 👩🏻 🧑🏻‍🦱 👨🏻‍🦱 👩🏻‍🦱 🧑🏻‍🦰 👨🏻‍🦰 👩🏻‍🦰 👱🏻 👱🏻‍♂️ 👱🏻‍♀️ 🧑🏻‍🦳 👩🏻‍🦳 👨🏻‍🦳 🧑🏻‍🦲 👨🏻‍🦲 👩🏻‍🦲 🧔🏻 🧓🏻 👴🏻 👵🏻 🙍🏻 🙍🏻‍♂️ 🙍🏻‍♀️ 🙎🏻 🙎🏻‍♂️ 🙎🏻‍♀️ 🙅🏻 🙅🏻‍♂️ 🙅🏻‍♀️ 🙆🏻 🙆🏻‍♂️ 🙆🏻‍♀️ 💁🏻 💁🏻‍♂️ 💁🏻‍♀️ 🙋🏻 🙋🏻‍♂️ 🙋🏻‍♀️ 🧏🏻 🧏🏻‍♂️ 🧏🏻‍♀️ 🙇🏻 🙇🏻‍♂️ 🙇🏻‍♀️ 🤦🏻 🤦🏻‍♂️ 🤦🏻‍♀️ 🤷🏻 🤷🏻‍♂️ 🤷🏻‍♀️ 🧑🏻‍⚕️ 👨🏻‍⚕️ 👩🏻‍⚕️ 🧑🏻‍🎓 👨🏻‍🎓 👩🏻‍🎓 🧑🏻‍🏫 👨🏻‍🏫 👩🏻‍🏫 🧑🏻‍⚖️ 👨🏻‍⚖️ 👩🏻‍⚖️ 🧑🏻‍🌾 👨🏻‍🌾 👩🏻‍🌾 🧑🏻‍🍳 👨🏻‍🍳 👩🏻‍🍳 🧑🏻‍🔧 👨🏻‍🔧 👩🏻‍🔧 🧑🏻‍🏭 👨🏻‍🏭 👩🏻‍🏭 🧑🏻‍💼 👨🏻‍💼 👩🏻‍💼 🧑🏻‍🔬 👨🏻‍🔬 👩🏻‍🔬 🧑🏻‍💻 👨🏻‍💻 👩🏻‍💻 🧑🏻‍🎤 👨🏻‍🎤 👩🏻‍🎤 🧑🏻‍🎨 👨🏻‍🎨 👩🏻‍🎨 🧑🏻‍✈️ 👨🏻‍✈️ 👩🏻‍✈️ 🧑🏻‍🚀 👨🏻‍🚀 👩🏻‍🚀 🧑🏻‍🚒 👨🏻‍🚒 👩🏻‍🚒 👮🏻 👮🏻‍♂️ 👮🏻‍♀️ 🕵🏻 🕵🏻‍♂️ 🕵🏻‍♀️ 💂🏻 💂🏻‍♂️ 💂🏻‍♀️ 👷🏻 👷🏻‍♂️ 👷🏻‍♀️ 🤴🏻 👸🏻 👳🏻 👳🏻‍♂️ 👳🏻‍♀️ 👲🏻 🧕🏻 🤵🏻 👰🏻 🤰🏻 🤱🏻 👼🏻 🎅🏻 🤶🏻 🦸🏻 🦸🏻‍♂️ 🦸🏻‍♀️ 🦹🏻 🦹🏻‍♂️ 🦹🏻‍♀️ 🧙🏻 🧙🏻‍♂️ 🧙🏻‍♀️ 🧚🏻 🧚🏻‍♂️ 🧚🏻‍♀️ 🧛🏻 🧛🏻‍♂️ 🧛🏻‍♀️ 🧜🏻 🧜🏻‍♂️ 🧜🏻‍♀️ 🧝🏻 🧝🏻‍♂️ 🧝🏻‍♀️ 💆🏻 💆🏻‍♂️ 💆🏻‍♀️ 💇🏻 💇🏻‍♂️ 💇🏻‍♀️ 🚶🏻 🚶🏻‍♂️ 🚶🏻‍♀️ 🧍🏻 🧍🏻‍♂️ 🧍🏻‍♀️ 🧎🏻 🧎🏻‍♂️ 🧎🏻‍♀️ 🧑🏻‍🦯 👨🏻‍🦯 👩🏻‍🦯 🧑🏻‍🦼 👨🏻‍🦼 👩🏻‍🦼 🧑🏻‍🦽 👨🏻‍🦽 👩🏻‍🦽 🏃🏻 🏃🏻‍♂️ 🏃🏻‍♀️ 💃🏻 🕺🏻 🕴🏻 🧖🏻 🧖🏻‍♂️ 🧖🏻‍♀️ 🧗🏻 🧗🏻‍♂️ 🧗🏻‍♀️ 🏇🏻 🏂🏻 🏌🏻 🏌🏻‍♂️ 🏌🏻‍♀️ 🏄🏻 🏄🏻‍♂️ 🏄🏻‍♀️ 🚣🏻 🚣🏻‍♂️ 🚣🏻‍♀️ 🏊🏻 🏊🏻‍♂️ 🏊🏻‍♀️ ⛹🏻 ⛹🏻‍♂️ ⛹🏻‍♀️ 🏋🏻 🏋🏻‍♂️ 🏋🏻‍♀️ 🚴🏻 🚴🏻‍♂️ 🚴🏻‍♀️ 🚵🏻 🚵🏻‍♂️ 🚵🏻‍♀️ 🤸🏻 🤸🏻‍♂️ 🤸🏻‍♀️ 🤽🏻 🤽🏻‍♂️ 🤽🏻‍♀️ 🤾🏻 🤾🏻‍♂️ 🤾🏻‍♀️ 🤹🏻 🤹🏻‍♂️ 🤹🏻‍♀️ 🧘🏻 🧘🏻‍♂️ 🧘🏻‍♀️ 🛀🏻 🛌🏻 🧑🏻‍🤝‍🧑🏻 👬🏻 👭🏻 👫🏻'
// ignore: missing_whitespace_between_adjacent_strings
    '🧳 🌂 ☂️ 🧵 🧶 👓 🕶 🥽 🥼 🦺 👔 👕 👖 🧣 🧤 🧥 🧦 👗 👘 🥻 🩱 🩲 🩳 👙 👚 👛 👜 👝 🎒 👞 👟 🥾 🥿 👠 👡 🩰 👢 👑 👒 🎩 🎓 🧢 ⛑ 💄 💍 💼'
// ignore: missing_whitespace_between_adjacent_strings
    '👶 🧒 👦 👧 🧑 👱 👨 🧔 👨‍🦰 👨‍🦱 👨‍🦳 👨‍🦲 👩 👩‍🦰 🧑‍🦰 👩‍🦱 🧑‍🦱 👩‍🦳 🧑‍🦳 👩‍🦲 🧑‍🦲 👱‍♀️ 👱‍♂️ 🧓 👴 👵 🙍 🙍‍♂️ 🙍‍♀️ 🙎 🙎‍♂️ 🙎‍♀️ 🙅 🙅‍♂️ 🙅‍♀️ 🙆 🙆‍♂️ 🙆‍♀️ 💁 💁‍♂️ 💁‍♀️ 🙋 🙋‍♂️ 🙋‍♀️ 🧏 🧏‍♂️ 🧏‍♀️ 🙇 🙇‍♂️ 🙇‍♀️ 🤦 🤦‍♂️ 🤦‍♀️ 🤷 🤷‍♂️ 🤷‍♀️ 🧑‍⚕️ 👨‍⚕️ 👩‍⚕️ 🧑‍🎓 👨‍🎓 👩‍🎓 🧑‍🏫 👨‍🏫 👩‍🏫 🧑‍⚖️ 👨‍⚖️ 👩‍⚖️ 🧑‍🌾 👨‍🌾 👩‍🌾 🧑‍🍳 👨‍🍳 👩‍🍳 🧑‍🔧 👨‍🔧 👩‍🔧 🧑‍🏭 👨‍🏭 👩‍🏭 🧑‍💼 👨‍💼 👩‍💼 🧑‍🔬 👨‍🔬 👩‍🔬 🧑‍💻 👨‍💻 👩‍💻 🧑‍🎤 👨‍🎤 👩‍🎤 🧑‍🎨 👨‍🎨 👩‍🎨 🧑‍✈️ 👨‍✈️ 👩‍✈️ 🧑‍🚀 👨‍🚀 👩‍🚀 🧑‍🚒 👨‍🚒 👩‍🚒 👮 👮‍♂️ 👮‍♀️ 🕵 🕵️‍♂️ 🕵️‍♀️ 💂 💂‍♂️ 💂‍♀️ 👷 👷‍♂️ 👷‍♀️ 🤴 👸 👳 👳‍♂️ 👳‍♀️ 👲 🧕 🤵 👰 🤰 🤱 👼 🎅 🤶 🦸 🦸‍♂️ 🦸‍♀️ 🦹 🦹‍♂️ 🦹‍♀️ 🧙 🧙‍♂️ 🧙‍♀️ 🧚 🧚‍♂️ 🧚‍♀️ 🧛 🧛‍♂️ 🧛‍♀️ 🧜 🧜‍♂️ 🧜‍♀️ 🧝 🧝‍♂️ 🧝‍♀️ 🧞 🧞‍♂️ 🧞‍♀️ 🧟 🧟‍♂️ 🧟‍♀️ 💆 💆‍♂️ 💆‍♀️ 💇 💇‍♂️ 💇‍♀️ 🚶 🚶‍♂️ 🚶‍♀️ 🧍 🧍‍♂️ 🧍‍♀️ 🧎 🧎‍♂️ 🧎‍♀️ 🧑‍🦯 👨‍🦯 👩‍🦯 🧑‍🦼 👨‍🦼 👩‍🦼 🧑‍🦽 👨‍🦽 👩‍🦽 🏃 🏃‍♂️ 🏃‍♀️ 💃 🕺 🕴 👯 👯‍♂️ 👯‍♀️ 🧖 🧖‍♂️ 🧖‍♀️ 🧘 🧑‍🤝‍🧑 👭 👫 👬 💏 👨‍❤️‍💋‍👨 👩‍❤️‍💋‍👩 💑 👨‍❤️‍👨 👩‍❤️‍👩 👪 👨‍👩‍👦 👨‍👩‍👧 👨‍👩‍👧‍👦 👨‍👩‍👦‍👦 👨‍👩‍👧‍👧 👨‍👨‍👦 👨‍👨‍👧 👨‍👨‍👧‍👦 👨‍👨‍👦‍👦 👨‍👨‍👧‍👧 👩‍👩‍👦 👩‍👩‍👧 👩‍👩‍👧‍👦 👩‍👩‍👦‍👦 👩‍👩‍👧‍👧 👨‍👦 👨‍👦‍👦 👨‍👧 👨‍👧‍👦 👨‍👧‍👧 👩‍👦 👩‍👦‍👦 👩‍👧 👩‍👧‍👦 👩‍👧‍👧 🗣 👤 👥 👣'
// ignore: missing_whitespace_between_adjacent_strings
    '👋 🤚 🖐 ✋ 🖖 👌 🤏 ✌️ 🤞 🤟 🤘 🤙 👈 👉 👆 🖕 👇 ☝️ 👍 👎 ✊ 👊 🤛 🤜 👏 🙌 👐 🤲 🤝 🙏 ✍️ 💅 🤳 💪 🦾 🦵 🦿 🦶 👂 🦻 👃 🧠 🦷 🦴 👀 👁 👅 👄 💋 🩸'
// ignore: missing_whitespace_between_adjacent_strings
    '😀 😃 😄 😁 😆 😅 😂 🤣 ☺️ 😊 😇 🙂 🙃 😉 😌 😍 🥰 😘 😗 😙 😚 😋 😛 😝 😜 🤪 🤨 🧐 🤓 😎 🤩 🥳 😏 😒 😞 😔 😟 😕 🙁 ☹️ 😣 😖 😫 😩 🥺 😢 😭 😤 😠 😡 🤬 🤯 😳 🥵 🥶 😱 😨 😰 😥 😓 🤗 🤔 🤭 🤫 🤥 😶 😐 😑 😬 🙄 😯 😦 😧 😮 😲 🥱 😴 🤤 😪 😵 🤐 🥴 🤢 🤮 🤧 😷 🤒 🤕 🤑 🤠 😈 👿 👹 👺 🤡 💩 👻 💀 ☠️ 👽 👾 🤖 🎃 😺 😸 😹 😻 😼 😽 🙀 😿 😾';

void main() {
  test('测试emoji筛选', () {
    final List<String> emojis =
        Characters(emojiString.replaceAll(' ', '')).toList();
    for (var i = 0; i < 100; ++i) testEmojiRandom(emojis);

//    final Characters emojis = Characters('⭕');
//    testEmoji(emojis);
  });
}

void testEmoji(Characters emojis) {
  final List<String> emojiList = [];
  for (final emoji in emojis) {
    print('runes:${emoji.runes.length}    length:${emoji.length}');
    if (emoji != ' ') emojiList.add(emoji);
  }
  final List<Characters> emojiCollection = reSortEmoji(emojiList, 6);

  ///将emoji按照数量从小到大排序
  emojiCollection.sort((a, b) => a.length - b.length);
  bool allPassed = true;
  emojiCollection.forEach((element) {
    if (!isAllEmo(element)) {
      print("$element  --->  该emoji无法验证通过  ❌");
      allPassed = false;
    }
  });
  if (allPassed) print('$emojiList \n ✅ 全部emoji测试通过 \n\n');
}

void testEmojiRandom(List<String> emojis) {
  final List<String> emojiList = [];
  int i = 0;
  final int randomNum = Random().nextInt(emojis.length - 6);
  while (i < 6 && randomNum + i < emojis.length) {
    final emoji = emojis[randomNum + i];
    if (emoji != ' ') {
      emojiList.add(emoji);
      i++;
    }
  }
  final List<Characters> emojiCollection = reSortEmoji(emojiList, 6);

  ///将emoji按照数量从小到大排序
  emojiCollection.sort((a, b) => a.length - b.length);
  bool allPassed = true;
  emojiCollection.forEach((element) {
    if (!isAllEmo(element)) {
      print("$element  --->  该emoji无法验证通过  ❌");
      allPassed = false;
    }
  });
  if (allPassed) print('$emojiList \n ✅ 全部emoji测试通过 \n\n');
}


///通过回溯来对输入数组进行排列,[limitedNum]用于限制每个排列的emoji数量
List<Characters> reSortEmoji(List<String> inputEmojis, int limitedNum) {
  final List<Characters> result = [];
  _backtraceEmoji(result, 0, inputEmojis, '', limitedNum);
  return result;
}

void _backtraceEmoji(List<Characters> result, int index,
    List<String> inputEmojis, String curEmoji, int limitedNum) {
  final Characters char = Characters(curEmoji);
  if (char.length > limitedNum) return;
  result.add(char);
  for (int i = index; i < inputEmojis.length; i++) {
    _backtraceEmoji(result, i + 1, inputEmojis,
        (curEmoji + inputEmojis[i]).toString(), limitedNum);
  }
}
