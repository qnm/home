def without($base; $previous):
  if ($base | type) == "object" and ($previous | type) == "object" then
    reduce ($previous | keys_unsorted[]) as $key ($base;
      if has($key) then .[$key] = without(.[$key]; $previous[$key]) else . end)
  elif ($base | type) == "array" and ($previous | type) == "array" then
    [$base[] | select(. as $entry | $previous | index([$entry]) | not)]
  else
    $base
  end;

def merge($base; $override):
  if ($base | type) == "object" and ($override | type) == "object" then
    reduce ($override | keys_unsorted[]) as $key ($base; .[$key] = merge($base[$key]; $override[$key]))
  elif ($base | type) == "array" and ($override | type) == "array" then
    $base + [$override[] | select(. as $entry | $base | index([$entry]) | not)]
  else
    $override
  end;

merge(without(.[0]; .[1]); .[2])
