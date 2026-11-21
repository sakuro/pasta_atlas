// mapPath already carries the selected generation, which wins over whatever the
// address bar holds; the remaining parameters (position, zoom, surface) come from the
// current location.
export const buildShareUrl = (origin: string, mapPath: string, currentSearch: string): string => {
  // Concatenating the two strings would produce a second "?", so the parameters are merged.
  const url = new URL(mapPath, origin);
  for (const [key, value] of new URLSearchParams(currentSearch)) {
    if (!url.searchParams.has(key)) url.searchParams.set(key, value);
  }
  return url.toString();
};
