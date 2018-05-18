defmodule EventHelp do
  def events_for(calendar) do
    try do
      :event_cache
      |> Stash.get("Calendar: #{calendar}")
      |> Enum.map(fn slug -> Stash.get(:event_cache, slug) end)
      |> Enum.sort(&EventHelp.date_compare/2)
    rescue
      _e -> []
    end
  end

  defp humanize_date(dt) do
    %DateTime{month: month, day: day} = parse(dt)

    month =
      [
        "January",
        "February",
        "March",
        "April",
        "May",
        "June",
        "July",
        "August",
        "September",
        "October",
        "November",
        "December"
      ]
      |> Enum.at(month - 1)

    "#{month}, #{day} "
  end

  defp humanize_time(dt) do
    %DateTime{hour: hour, minute: minute} = parse(dt)

    {hour, am_pm} = if hour >= 12, do: {hour - 12, "PM"}, else: {hour, "AM"}
    hour = if hour == 0, do: 12, else: hour
    minute = if minute == 0, do: "", else: ":#{minute}"

    "#{hour}#{minute} " <> am_pm
  end

  def parse(dt) do
    # iso = if String.ends_with?(dt, "Z"), do: dt, else: dt <> "Z"
    {:ok, result, _} = DateTime.from_iso8601(dt)
    result
  end

  def set_browser_url(ev = %{name: name}), do: Map.put(ev, :browser_url, "/events/#{name}")

  def date_compare(%{"start_date" => d1}, %{"start_date" => d2}) do
    d1 = parse(d1)
    d2 = parse(d2)

    case DateTime.compare(d1, d2) do
      :gt -> false
      _ -> true
    end
  end

  def add_candidate_attr(event) do
    candidate =
      event["tags"]
      |> Enum.filter(&String.contains?(&1, "Calendar: "))
      |> Enum.map(&(&1 |> String.split(":") |> List.last() |> String.trim()))
      |> Enum.reject(&(&1 == "Brand New Congress" or &1 == "Justice Democrats"))
      |> List.first()

    candidate = candidate || "Justice Democrats"
    Map.put(event, :candidate, candidate)
  end
end
