export const getParam = (key: string): string | null =>
  new URLSearchParams(window.location.search).get(key);

export const setParams = (updates: Record<string, string | null>) => {
  const params = new URLSearchParams(window.location.search);
  for (const [key, value] of Object.entries(updates)) {
    if (value === null) params.delete(key);
    else params.set(key, value);
  }
  history.replaceState(null, "", `?${params}`);
};
