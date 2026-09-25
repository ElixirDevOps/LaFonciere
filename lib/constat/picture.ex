defmodule Constat.Picture do
  @moduledoc """
  Takes the picture a check is asked to take: renders the lines a person would see on their
  terminal and writes them as a PNG under `.constat/pictures/`, named after the check that took
  it. CI publishes that directory and Constat shows the picture beside the criterion.

      Constat.Picture.write!("foundation > answers with its name", ["$ mix serve", answer])
      #=> ".constat/pictures/foundation-answers-with-its-name.png"

  No image dependency, for the same reason `Constat.CheckReportFormatter` hand-rolls its JSON:
  the picture this takes is a two-colour terminal transcript in a fixed 5x7 font, which is small
  enough to encode here, and encoding it here means a check can take its picture in any checkout
  without that checkout first having to agree to an image library. PNG is assembled from its four
  chunks over `:zlib` and `:erlang.crc32`, both of which ship with Erlang.
  """

  # The terminal this draws: dark background, light text, one 5x7 glyph per character cell with a
  # one-pixel gutter, then everything scaled up so the result is legible at a glance.
  @scale 3
  @padding 12
  @cell_width 6
  @cell_height 9
  @background {13, 17, 23}
  @foreground {201, 209, 217}

  @pictures_dir ".constat/pictures"

  @doc """
  Renders `lines` and writes the picture for `check_name`. Returns the path it wrote.
  """
  def write!(check_name, lines) when is_binary(check_name) and is_list(lines) do
    path = Path.join(@pictures_dir, slug(check_name) <> ".png")
    File.mkdir_p!(Path.dirname(path))
    File.write!(path, render(lines))
    path
  end

  @doc """
  The file name Constat expects for a check: lower-case, every run of anything but a letter or a
  digit becomes one dash, no leading or trailing dash, at most 120 characters.
  """
  def slug(check_name) do
    check_name
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9]+/, "-")
    |> String.slice(0, 120)
    |> String.trim("-")
  end

  @doc "The PNG bytes for `lines`, without writing them anywhere."
  def render(lines) do
    columns = lines |> Enum.map(&String.length/1) |> Enum.max(fn -> 0 end) |> max(1)
    rows = max(length(lines), 1)

    lit = lit_cells(lines)
    grid_width = columns * @cell_width
    grid_height = rows * @cell_height
    width = grid_width * @scale + 2 * @padding
    height = grid_height * @scale + 2 * @padding

    png(width, height, scanlines(lit, width, height, grid_width, grid_height))
  end

  # Every {column, row} of the character grid that carries ink, once, so drawing a pixel is a set
  # lookup rather than a walk back through the text.
  defp lit_cells(lines) do
    for {line, line_index} <- Enum.with_index(lines),
        {character, column} <- Enum.with_index(String.to_charlist(line)),
        {glyph_row, glyph_y} <- Enum.with_index(glyph(character)),
        {pixel, glyph_x} <- Enum.with_index(String.to_charlist(glyph_row)),
        pixel == ?1,
        into: MapSet.new(),
        do: {column * @cell_width + glyph_x, line_index * @cell_height + glyph_y}
  end

  defp scanlines(lit, width, height, grid_width, grid_height) do
    background = pixel(@background)
    foreground = pixel(@foreground)

    for y <- 0..(height - 1), into: <<>> do
      row =
        for x <- 0..(width - 1), into: <<>> do
          if lit?(lit, x, y, grid_width, grid_height), do: foreground, else: background
        end

      # Filter type 0 (none) for every scanline: the image is two colours and tiny, so there is
      # nothing a filter would win back.
      <<0>> <> row
    end
  end

  defp lit?(lit, x, y, grid_width, grid_height) do
    grid_x = div(x - @padding, @scale)
    grid_y = div(y - @padding, @scale)

    x >= @padding and y >= @padding and grid_x < grid_width and grid_y < grid_height and
      MapSet.member?(lit, {grid_x, grid_y})
  end

  defp pixel({red, green, blue}), do: <<red, green, blue>>

  @signature <<137, 80, 78, 71, 13, 10, 26, 10>>

  defp png(width, height, raw) do
    # Bit depth 8, colour type 2 (truecolour), no compression/filter/interlace variations.
    header = <<width::32, height::32, 8, 2, 0, 0, 0>>

    @signature <>
      chunk("IHDR", header) <> chunk("IDAT", :zlib.compress(raw)) <> chunk("IEND", <<>>)
  end

  defp chunk(type, data) do
    <<byte_size(data)::32>> <> type <> data <> <<:erlang.crc32(type <> data)::32>>
  end

  # A 5x7 bitmap font, one clause per character, seven rows of five pixels each. Anything not
  # listed is drawn as a hollow box, so an unexpected character shows up in the picture as a
  # missing glyph instead of crashing the check that was taking it.
  defp glyph(?\s), do: ~w(00000 00000 00000 00000 00000 00000 00000)
  defp glyph(?0), do: ~w(01110 10001 10011 10101 11001 10001 01110)
  defp glyph(?1), do: ~w(00100 01100 00100 00100 00100 00100 01110)
  defp glyph(?2), do: ~w(01110 10001 00001 00010 00100 01000 11111)
  defp glyph(?3), do: ~w(11111 00010 00100 00010 00001 10001 01110)
  defp glyph(?4), do: ~w(00010 00110 01010 10010 11111 00010 00010)
  defp glyph(?5), do: ~w(11111 10000 11110 00001 00001 10001 01110)
  defp glyph(?6), do: ~w(00110 01000 10000 11110 10001 10001 01110)
  defp glyph(?7), do: ~w(11111 00001 00010 00100 01000 01000 01000)
  defp glyph(?8), do: ~w(01110 10001 10001 01110 10001 10001 01110)
  defp glyph(?9), do: ~w(01110 10001 10001 01111 00001 00010 01100)
  defp glyph(?A), do: ~w(01110 10001 10001 11111 10001 10001 10001)
  defp glyph(?B), do: ~w(11110 10001 10001 11110 10001 10001 11110)
  defp glyph(?C), do: ~w(01110 10001 10000 10000 10000 10001 01110)
  defp glyph(?D), do: ~w(11100 10010 10001 10001 10001 10010 11100)
  defp glyph(?E), do: ~w(11111 10000 10000 11110 10000 10000 11111)
  defp glyph(?F), do: ~w(11111 10000 10000 11110 10000 10000 10000)
  defp glyph(?G), do: ~w(01110 10001 10000 10111 10001 10001 01111)
  defp glyph(?H), do: ~w(10001 10001 10001 11111 10001 10001 10001)
  defp glyph(?I), do: ~w(01110 00100 00100 00100 00100 00100 01110)
  defp glyph(?J), do: ~w(00111 00010 00010 00010 00010 10010 01100)
  defp glyph(?K), do: ~w(10001 10010 10100 11000 10100 10010 10001)
  defp glyph(?L), do: ~w(10000 10000 10000 10000 10000 10000 11111)
  defp glyph(?M), do: ~w(10001 11011 10101 10101 10001 10001 10001)
  defp glyph(?N), do: ~w(10001 11001 10101 10011 10001 10001 10001)
  defp glyph(?O), do: ~w(01110 10001 10001 10001 10001 10001 01110)
  defp glyph(?P), do: ~w(11110 10001 10001 11110 10000 10000 10000)
  defp glyph(?Q), do: ~w(01110 10001 10001 10001 10101 10010 01101)
  defp glyph(?R), do: ~w(11110 10001 10001 11110 10100 10010 10001)
  defp glyph(?S), do: ~w(01111 10000 10000 01110 00001 00001 11110)
  defp glyph(?T), do: ~w(11111 00100 00100 00100 00100 00100 00100)
  defp glyph(?U), do: ~w(10001 10001 10001 10001 10001 10001 01110)
  defp glyph(?V), do: ~w(10001 10001 10001 10001 10001 01010 00100)
  defp glyph(?W), do: ~w(10001 10001 10001 10101 10101 11011 10001)
  defp glyph(?X), do: ~w(10001 10001 01010 00100 01010 10001 10001)
  defp glyph(?Y), do: ~w(10001 10001 01010 00100 00100 00100 00100)
  defp glyph(?Z), do: ~w(11111 00001 00010 00100 01000 10000 11111)
  defp glyph(?a), do: ~w(00000 00000 01110 00001 01111 10001 01111)
  defp glyph(?b), do: ~w(10000 10000 11110 10001 10001 10001 11110)
  defp glyph(?c), do: ~w(00000 00000 01111 10000 10000 10000 01111)
  defp glyph(?d), do: ~w(00001 00001 01111 10001 10001 10001 01111)
  defp glyph(?e), do: ~w(00000 00000 01110 10001 11111 10000 01110)
  defp glyph(?f), do: ~w(00110 01001 01000 11100 01000 01000 01000)
  defp glyph(?g), do: ~w(00000 00000 01111 10001 01111 00001 01110)
  defp glyph(?h), do: ~w(10000 10000 11110 10001 10001 10001 10001)
  defp glyph(?i), do: ~w(00100 00000 01100 00100 00100 00100 01110)
  defp glyph(?j), do: ~w(00010 00000 00110 00010 00010 10010 01100)
  defp glyph(?k), do: ~w(10000 10000 10010 10100 11000 10100 10010)
  defp glyph(?l), do: ~w(01100 00100 00100 00100 00100 00100 01110)
  defp glyph(?m), do: ~w(00000 00000 11010 10101 10101 10101 10101)
  defp glyph(?n), do: ~w(00000 00000 11110 10001 10001 10001 10001)
  defp glyph(?o), do: ~w(00000 00000 01110 10001 10001 10001 01110)
  defp glyph(?p), do: ~w(00000 00000 11110 10001 11110 10000 10000)
  defp glyph(?q), do: ~w(00000 00000 01111 10001 01111 00001 00001)
  defp glyph(?r), do: ~w(00000 00000 10110 11001 10000 10000 10000)
  defp glyph(?s), do: ~w(00000 00000 01111 10000 01110 00001 11110)
  defp glyph(?t), do: ~w(01000 01000 11100 01000 01000 01001 00110)
  defp glyph(?u), do: ~w(00000 00000 10001 10001 10001 10011 01101)
  defp glyph(?v), do: ~w(00000 00000 10001 10001 10001 01010 00100)
  defp glyph(?w), do: ~w(00000 00000 10001 10101 10101 10101 01010)
  defp glyph(?x), do: ~w(00000 00000 10001 01010 00100 01010 10001)
  defp glyph(?y), do: ~w(00000 00000 10001 10001 01111 00001 01110)
  defp glyph(?z), do: ~w(00000 00000 11111 00010 00100 01000 11111)
  defp glyph(?.), do: ~w(00000 00000 00000 00000 00000 01100 01100)
  defp glyph(?,), do: ~w(00000 00000 00000 00000 01100 00100 01000)
  defp glyph(?:), do: ~w(00000 01100 01100 00000 01100 01100 00000)
  defp glyph(?;), do: ~w(00000 01100 01100 00000 01100 00100 01000)
  defp glyph(?-), do: ~w(00000 00000 00000 11111 00000 00000 00000)
  defp glyph(?_), do: ~w(00000 00000 00000 00000 00000 00000 11111)
  defp glyph(?!), do: ~w(00100 00100 00100 00100 00100 00000 00100)
  defp glyph(??), do: ~w(01110 10001 00001 00010 00100 00000 00100)
  defp glyph(?/), do: ~w(00001 00010 00010 00100 01000 01000 10000)
  defp glyph(?\\), do: ~w(10000 01000 01000 00100 00010 00010 00001)
  defp glyph(?(), do: ~w(00010 00100 01000 01000 01000 00100 00010)
  defp glyph(?)), do: ~w(01000 00100 00010 00010 00010 00100 01000)
  defp glyph(?[), do: ~w(01110 01000 01000 01000 01000 01000 01110)
  defp glyph(?]), do: ~w(01110 00010 00010 00010 00010 00010 01110)
  defp glyph(?{), do: ~w(00110 01000 01000 11000 01000 01000 00110)
  defp glyph(?}), do: ~w(01100 00010 00010 00011 00010 00010 01100)
  defp glyph(?$), do: ~w(00100 01111 10100 01110 00101 11110 00100)
  defp glyph(?%), do: ~w(11000 11001 00010 00100 01000 10011 00011)
  defp glyph(?&), do: ~w(01100 10010 10100 01000 10101 10010 01101)
  defp glyph(?@), do: ~w(01110 10001 10111 10101 10111 10000 01110)
  defp glyph(?#), do: ~w(01010 01010 11111 01010 11111 01010 01010)
  defp glyph(?*), do: ~w(00000 10101 01110 11111 01110 10101 00000)
  defp glyph(?+), do: ~w(00000 00100 00100 11111 00100 00100 00000)
  defp glyph(?=), do: ~w(00000 00000 11111 00000 11111 00000 00000)
  defp glyph(?<), do: ~w(00010 00100 01000 10000 01000 00100 00010)
  defp glyph(?>), do: ~w(01000 00100 00010 00001 00010 00100 01000)
  defp glyph(?|), do: ~w(00100 00100 00100 00100 00100 00100 00100)
  defp glyph(?~), do: ~w(00000 00000 01001 10110 00000 00000 00000)
  defp glyph(?^), do: ~w(00100 01010 10001 00000 00000 00000 00000)
  defp glyph(?'), do: ~w(00100 00100 01000 00000 00000 00000 00000)
  defp glyph(?"), do: ~w(01010 01010 01010 00000 00000 00000 00000)
  defp glyph(?`), do: ~w(01000 00100 00000 00000 00000 00000 00000)
  defp glyph(_unknown), do: ~w(11111 10001 10001 10001 10001 10001 11111)
end
