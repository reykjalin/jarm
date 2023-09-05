defmodule AvatarGenerators.Cat do
  def build_cat(output), do: build_cat(output, "", 400)
  def build_cat(output, seed), do: build_cat(output, seed, 400)

  def build_cat(output, seed, size) do
    if seed != "" do
      {seed, _remainder} =
        :crypto.hash(:md5, seed) |> Base.encode16() |> String.slice(0, 6) |> Integer.parse(16)

      # :exsss is the current default :rand PRNG algorithm.
      :rand.seed(:exsss, seed)
    end

    parts = [
      "body_#{:rand.uniform(15)}.png",
      "fur_#{:rand.uniform(10)}.png",
      "eyes_#{:rand.uniform(15)}.png",
      "mouth_#{:rand.uniform(10)}.png",
      "accessorie_#{:rand.uniform(20)}.png"
    ]

    ImageMagick.generate_avatar_from_parts(parts, output, size)
  end
end
