import { afterEach, describe, expect, it, vi } from "vitest";
import { deleteUser, errorKey, lookupMap, updateMapName } from "./client";

describe("client", () => {
  afterEach(() => {
    vi.unstubAllGlobals();
    document.head.innerHTML = "";
  });

  it("sends the CSRF token of the page with each request", async () => {
    document.head.innerHTML = '<meta name="csrf-token" content="token-1">';
    const fetchMock = vi.fn(
      async (_request: Request) =>
        new Response(JSON.stringify({ display_name: "renamed" }), {
          status: 200,
          headers: { "Content-Type": "application/json" },
        })
    );
    vi.stubGlobal("fetch", fetchMock);

    const { data } = await updateMapName({ path: { ulid: "01MAP" }, body: { name: "renamed" } });

    const request = fetchMock.mock.calls[0][0];
    expect(new URL(request.url).pathname).toBe("/api/v1/maps/01MAP/name");
    expect(request.headers.get("X-CSRF-Token")).toBe("token-1");
    expect(request.headers.get("Content-Type")).toBe("application/json");
    expect(await request.json()).toEqual({ name: "renamed" });
    expect(data).toEqual({ display_name: "renamed" });
  });

  it("returns a network error instead of throwing", async () => {
    vi.stubGlobal("fetch", async () => {
      throw new TypeError("Failed to fetch");
    });

    const { data, error, response } = await lookupMap({ query: { mapshot_map_id: "ae8ec3ab" } });

    expect(data).toBeUndefined();
    expect(error).toBeInstanceOf(TypeError);
    expect(response).toBeUndefined();
  });

  it("returns the body and the status of an error response", async () => {
    vi.stubGlobal(
      "fetch",
      async () => new Response("Not Found", { status: 404, headers: { "Content-Type": "text/plain" } })
    );

    const { data, error, response } = await lookupMap({ query: { mapshot_map_id: "ae8ec3ab" } });

    expect(data).toBeUndefined();
    expect(error).toBe("Not Found");
    expect(response?.status).toBe(404);
  });

  it("sends the body of a DELETE", async () => {
    const fetchMock = vi.fn(
      async (_request: Request) =>
        new Response(JSON.stringify({ redirect_to: "/" }), {
          status: 200,
          headers: { "Content-Type": "application/json" },
        })
    );
    vi.stubGlobal("fetch", fetchMock);

    await deleteUser({ path: { user_name: "wube" }, body: { confirm_user_name: "wube" } });

    const request = fetchMock.mock.calls[0][0];
    expect(request.method).toBe("DELETE");
    expect(new URL(request.url).pathname).toBe("/api/v1/users/wube");
    expect(await request.json()).toEqual({ confirm_user_name: "wube" });
  });
});

describe("errorKey", () => {
  it("returns the key of an error body", () => {
    expect(errorKey({ error: "error-map-name-too-long" })).toBe("error-map-name-too-long");
  });

  it("returns undefined for anything else", () => {
    expect(errorKey("Not Found")).toBeUndefined();
    expect(errorKey({ error: 1 })).toBeUndefined();
    expect(errorKey(null)).toBeUndefined();
  });
});
