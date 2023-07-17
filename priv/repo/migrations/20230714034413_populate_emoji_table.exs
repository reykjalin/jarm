defmodule Jarm.Repo.Migrations.PopulateEmojiTable do
  use Ecto.Migration

  alias Jarm.Repo

  def up do
    emojis = [
      %{
        emoji: "👍",
        name: "thumbs up",
        keywords: "+1 | hand | thumb | thumbs up | up",
        inserted_at: DateTime.utc_now()
      },
      %{
        emoji: "👎",
        name: "thumbs down",
        keywords: "-1 | down | hand | thumb | thumbs down",
        inserted_at: DateTime.utc_now()
      },
      %{
        emoji: "👏",
        name: "clapping hands",
        keywords: "clap | clapping hands | hand",
        inserted_at: DateTime.utc_now()
      },
      %{
        emoji: "🙌",
        name: "raising hands",
        keywords: "celebration | gesture | hand | hooray | raised | raising hands",
        inserted_at: DateTime.utc_now()
      },
      %{emoji: "👌", name: "OK hand", keywords: "hand | OK", inserted_at: DateTime.utc_now()},
      %{
        emoji: "🙏",
        name: "folded hands",
        keywords: "ask | folded hands | hand | high 5 | high five | please | pray | thanks",
        inserted_at: DateTime.utc_now()
      },
      %{
        emoji: "😁",
        name: "beaming face with smiling eyes",
        keywords: "beaming face with smiling eyes | eye | face | grin | smile",
        inserted_at: DateTime.utc_now()
      },
      %{
        emoji: "🤣",
        name: "rolling on the floor laughing",
        keywords: "face | floor | laugh | rofl | rolling | rolling on the floor laughing | rotfl",
        inserted_at: DateTime.utc_now()
      },
      %{
        emoji: "🤪",
        name: "zany face",
        keywords: "eye | goofy | large | small | zany face | silly",
        inserted_at: DateTime.utc_now()
      },
      %{
        emoji: "🥰",
        name: "smiling face with hearts",
        keywords: "adore | crush | hearts | in love | smiling face with hearts",
        inserted_at: DateTime.utc_now()
      },
      %{
        emoji: "😍",
        name: "smiling face with heart-eyes",
        keywords: "eye | face | love | smile | smiling face with heart-eyes",
        inserted_at: DateTime.utc_now()
      },
      %{
        emoji: "😘",
        name: "face blowing a kiss",
        keywords: "face | face blowing a kiss | kiss",
        inserted_at: DateTime.utc_now()
      },
      %{
        emoji: "❤️",
        name: "red heart",
        keywords: "heart | red heart",
        inserted_at: DateTime.utc_now()
      },
      %{
        emoji: "❤️‍🔥",
        name: "heart on fire",
        keywords: "burn | heart | heart on fire | love | lust | sacred heart",
        inserted_at: DateTime.utc_now()
      },
      %{
        emoji: "💘",
        name: "heart with arrow",
        keywords: "arrow | cupid | heart with arrow",
        inserted_at: DateTime.utc_now()
      },
      %{
        emoji: "💔",
        name: "broken heart",
        keywords: "break | broken | broken heart",
        inserted_at: DateTime.utc_now()
      },
      %{
        emoji: "💋",
        name: "kiss mark",
        keywords: "kiss | kiss mark | lips",
        inserted_at: DateTime.utc_now()
      },
      %{
        emoji: "🤗",
        name: "smiling face with open hands",
        keywords:
          "face | hug | hugging | open hands | smiling face | smiling face with open hands",
        inserted_at: DateTime.utc_now()
      },
      %{
        emoji: "🥹",
        name: "face holding back tears",
        keywords: "angry | cry | face holding back tears | proud | resist | sad | aww",
        inserted_at: DateTime.utc_now()
      },
      %{
        emoji: "🤩",
        name: "star-struck",
        keywords: "eyes | face | grinning | star | star-struck | starry-eyed",
        inserted_at: DateTime.utc_now()
      },
      %{
        emoji: "😇",
        name: "smiling face with halo",
        keywords: "angel | face | fantasy | halo | innocent | smiling face with halo",
        inserted_at: DateTime.utc_now()
      },
      %{
        emoji: "😎",
        name: "smiling face with sunglasses",
        keywords: "bright | cool | face | smiling face with sunglasses | sun | sunglasses",
        inserted_at: DateTime.utc_now()
      },
      %{
        emoji: "🤓",
        name: "nerd face",
        keywords: "face | geek | nerd",
        inserted_at: DateTime.utc_now()
      },
      %{
        emoji: "🫡",
        name: "saluting face",
        keywords: "OK | salute | saluting face | sunny | troops | yes",
        inserted_at: DateTime.utc_now()
      },
      %{
        emoji: "🤔",
        name: "thinking face",
        keywords: "face | thinking",
        inserted_at: DateTime.utc_now()
      },
      %{
        emoji: "🤨",
        name: "face with raised eyebrow",
        keywords:
          "distrust | face with raised eyebrow | skeptic | disapproval | disbelief | mild surprise | scepticism",
        inserted_at: DateTime.utc_now()
      },
      %{
        emoji: "😐",
        name: "neutral face",
        keywords: "deadpan | face | meh | neutral",
        inserted_at: DateTime.utc_now()
      },
      %{
        emoji: "🥱",
        name: "yawning face",
        keywords: "bored | tired | yawn | yawning face",
        inserted_at: DateTime.utc_now()
      },
      %{
        emoji: "😴",
        name: "sleeping face",
        keywords: "face | good night | sleep | sleeping face | ZZZ",
        inserted_at: DateTime.utc_now()
      },
      %{
        emoji: "😢",
        name: "crying face",
        keywords: "cry | crying face | face | sad | tear",
        inserted_at: DateTime.utc_now()
      },
      %{
        emoji: "😭",
        name: "loudly crying face",
        keywords: "cry | face | loudly crying face | sad | sob | tear",
        inserted_at: DateTime.utc_now()
      },
      %{
        emoji: "🤯",
        name: "exploding head",
        keywords: "exploding head | mind blown | shocked",
        inserted_at: DateTime.utc_now()
      },
      %{
        emoji: "😱",
        name: "face screaming in fear",
        keywords: "face | face screaming in fear | fear | munch | scared | scream",
        inserted_at: DateTime.utc_now()
      },
      %{
        emoji: "😨",
        name: "fearful face",
        keywords: "face | fear | fearful | scared",
        inserted_at: DateTime.utc_now()
      },
      %{
        emoji: "🤮",
        name: "face vomiting",
        keywords: "face vomiting | puke | sick | vomit | barf",
        inserted_at: DateTime.utc_now()
      },
      %{
        emoji: "🥴",
        name: "woozy face",
        keywords: "dizzy | intoxicated | tipsy | uneven eyes | wavy mouth | woozy face",
        inserted_at: DateTime.utc_now()
      },
      %{
        emoji: "😡",
        name: "enraged face",
        keywords: "angry | enraged | face | mad | pouting | rage | red",
        inserted_at: DateTime.utc_now()
      },
      %{
        emoji: "🤬",
        name: "face with symbols on mouth",
        keywords: "face with symbols on mouth | swearing | cursing",
        inserted_at: DateTime.utc_now()
      },
      %{
        emoji: "🧑‍💻",
        name: "technologist",
        keywords: "coder | developer | inventor | software | technologist",
        inserted_at: DateTime.utc_now()
      },
      %{
        emoji: "🤷‍♂️",
        name: "man shrugging",
        keywords: "doubt | ignorance | indifference | man | man shrugging | shrug",
        inserted_at: DateTime.utc_now()
      },
      %{
        emoji: "🤷‍♀️",
        name: "woman shrugging",
        keywords: "doubt | ignorance | indifference | shrug | woman | woman shrugging",
        inserted_at: DateTime.utc_now()
      },
      %{
        emoji: "🤷",
        name: "person shrugging",
        keywords: "doubt | ignorance | indifference | person shrugging | shrug",
        inserted_at: DateTime.utc_now()
      },
      %{
        emoji: "🖕",
        name: "middle finger",
        keywords: "finger | hand | middle finger",
        inserted_at: DateTime.utc_now()
      },
      %{
        emoji: "🤝",
        name: "handshake",
        keywords: "agreement | hand | handshake | meeting | shake",
        inserted_at: DateTime.utc_now()
      },
      %{
        emoji: "✍️",
        name: "writing hand",
        keywords: "hand | write | writing hand",
        inserted_at: DateTime.utc_now()
      },
      %{
        emoji: "💅",
        name: "nail polish",
        keywords: "care | cosmetics | manicure | nail | polish",
        inserted_at: DateTime.utc_now()
      },
      %{
        emoji: "🎅",
        name: "Santa Claus",
        keywords: "celebration | Christmas | claus | father | santa | Santa Claus",
        inserted_at: DateTime.utc_now()
      },
      %{
        emoji: "🤡",
        name: "clown face",
        keywords: "clown | face",
        inserted_at: DateTime.utc_now()
      },
      %{
        emoji: "😈",
        name: "smiling face with horns",
        keywords: "face | fairy tale | fantasy | horns | smile | smiling face with horns",
        inserted_at: DateTime.utc_now()
      },
      %{
        emoji: "👻",
        name: "ghost",
        keywords: "creature | face | fairy tale | fantasy | ghost | monster",
        inserted_at: DateTime.utc_now()
      },
      %{
        emoji: "☃️",
        name: "snowman",
        keywords: "cold | snow | snowman",
        inserted_at: DateTime.utc_now()
      },
      %{
        emoji: "👾",
        name: "alien monster",
        keywords: "alien | creature | extraterrestrial | face | monster | ufo",
        inserted_at: DateTime.utc_now()
      },
      %{
        emoji: "🙈",
        name: "see-no-evil monkey",
        keywords: "evil | face | forbidden | monkey | see | see-no-evil monkey",
        inserted_at: DateTime.utc_now()
      },
      %{
        emoji: "🙉",
        name: "hear-no-evil monkey",
        keywords: "evil | face | forbidden | hear | hear-no-evil monkey | monkey",
        inserted_at: DateTime.utc_now()
      },
      %{
        emoji: "🙊",
        name: "speak-no-evil monkey",
        keywords: "evil | face | forbidden | monkey | speak | speak-no-evil monkey",
        inserted_at: DateTime.utc_now()
      },
      %{
        emoji: "🔥",
        name: "fire",
        keywords: "fire | flame | tool",
        inserted_at: DateTime.utc_now()
      },
      %{
        emoji: "🎉",
        name: "party popper",
        keywords: "celebration | party | popper | tada",
        inserted_at: DateTime.utc_now()
      },
      %{emoji: "👀", name: "eyes", keywords: "eye | eyes | face", inserted_at: DateTime.utc_now()},
      %{
        emoji: "🎃",
        name: "jack-o-lantern",
        keywords: "celebration | halloween | jack | jack-o-lantern | lantern | pumpkin",
        inserted_at: DateTime.utc_now()
      },
      %{
        emoji: "💩",
        name: "pile of poo",
        keywords: "dung | face | monster | pile of poo | poo | poop",
        inserted_at: DateTime.utc_now()
      },
      %{
        emoji: "🕊️",
        name: "dove",
        keywords: "bird | dove | fly | peace",
        inserted_at: DateTime.utc_now()
      },
      %{
        emoji: "🐳",
        name: "spouting whale",
        keywords: "face | spouting | whale",
        inserted_at: DateTime.utc_now()
      },
      %{
        emoji: "🌚",
        name: "new moon face",
        keywords: "face | moon | new moon face",
        inserted_at: DateTime.utc_now()
      },
      %{
        emoji: "🌭",
        name: "hot dog",
        keywords: "frankfurter | hot dog | hotdog | sausage",
        inserted_at: DateTime.utc_now()
      },
      %{
        emoji: "⚡️",
        name: "high voltage",
        keywords: "danger | electric | high voltage | lightning | voltage | zap",
        inserted_at: DateTime.utc_now()
      },
      %{emoji: "🍌", name: "banana", keywords: "banana | fruit", inserted_at: DateTime.utc_now()},
      %{
        emoji: "🏆",
        name: "trophy",
        keywords: "prize | trophy | win | winner | cup",
        inserted_at: DateTime.utc_now()
      },
      %{
        emoji: "🍓",
        name: "strawberry",
        keywords: "berry | fruit | strawberry",
        inserted_at: DateTime.utc_now()
      },
      %{
        emoji: "🍾",
        name: "bottle with popping cork",
        keywords: "bar | bottle | bottle with popping cork | cork | drink | popping | champagne",
        inserted_at: DateTime.utc_now()
      },
      %{
        emoji: "🎄",
        name: "Christmas tree",
        keywords: "celebration | Christmas | tree",
        inserted_at: DateTime.utc_now()
      },
      %{
        emoji: "🗿",
        name: "moai",
        keywords: "face | moai | moyai | statue | Easter Island statue | human rock carving",
        inserted_at: DateTime.utc_now()
      },
      %{emoji: "🦄", name: "unicorn", keywords: "face | unicorn", inserted_at: DateTime.utc_now()},
      %{
        emoji: "💊",
        name: "pill",
        keywords: "doctor | medicine | pill | sick",
        inserted_at: DateTime.utc_now()
      },
      %{
        emoji: "💯",
        name: "hundred points",
        keywords: "100 | full | hundred | hundred points | score",
        inserted_at: DateTime.utc_now()
      },
      %{emoji: "🆒", name: "cool", keywords: "cool | neat | nice", inserted_at: DateTime.utc_now()}
    ]

    Repo.insert_all("emojis", emojis)
  end

  def down do
    # Do nothing.
  end
end
