// Terraform appends `const PAGE = <maintenance.html as a JSON string>;` after this code,
// so that the import stays the first statement as in AWS's examples.
import cf from "cloudfront";

const kvs = cf.kvs();

const DEFAULT_MESSAGE = "Pasta Atlas is down for maintenance. Please check back later.";

// get() rejects for a missing key. Checking exists() first would add a read to every request.
async function read(key) {
  try {
    return await kvs.get(key);
  } catch (e) {
    return null;
  }
}

function escapeHtml(text) {
  return text
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#39;");
}

// split/join instead of replace() so that `$` patterns in the message are not interpreted.
function fill(template, placeholder, value) {
  return template.split(placeholder).join(value);
}

async function handler(event) {
  const request = event.request;

  // Keys are read one at a time: promise combinators can exceed the function's memory quota.
  if ((await read("maintenance")) !== "on") return request;

  const allowIps = (await read("allow_ips")) || "";
  const allowed = allowIps.split(",").map((ip) => ip.trim());
  if (allowed.includes(event.viewer.ip)) return request;

  const message = (await read("message")) || DEFAULT_MESSAGE;
  let endsAt = await read("ends_at");
  const endsAtTime = endsAt ? Date.parse(endsAt) : NaN;
  if (isNaN(endsAtTime)) endsAt = null;

  const headers = { "cache-control": { value: "no-store" } };
  if (endsAt && endsAtTime > Date.now()) {
    headers["retry-after"] = { value: String(Math.ceil((endsAtTime - Date.now()) / 1000)) };
  }

  let data;
  if (request.uri.startsWith("/api/")) {
    headers["content-type"] = { value: "application/json" };
    data = JSON.stringify({ error: "maintenance", message: message, ends_at: endsAt });
  } else {
    headers["content-type"] = { value: "text/html; charset=utf-8" };
    const endsAtBlock = endsAt
      ? `<p>Expected to end at <time datetime="${escapeHtml(endsAt)}">${escapeHtml(endsAt)}</time>.</p>`
      : "";
    // The message goes in last so that a placeholder inside it is not replaced.
    data = fill(fill(PAGE, "{{ENDS_AT}}", endsAtBlock), "{{MESSAGE}}", escapeHtml(message));
  }

  return {
    statusCode: 503,
    statusDescription: "Service Unavailable",
    headers: headers,
    body: { encoding: "text", data: data },
  };
}
