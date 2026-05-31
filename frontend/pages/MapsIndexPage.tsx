import { createResource, For, Show } from "solid-js";
import { useSearchParams } from "@solidjs/router";
import { MapCard, type MapData } from "../components/MapCard";
import heroSrc from "../../app/assets/images/hero.webp";

type MapsResponse = {
  maps: MapData[];
  page: number;
  per_page: number;
  total: number;
};

const Pagination = (props: {
  page: number;
  perPage: number;
  total: number;
  onPageChange: (page: number) => void;
}) => {
  const hasPrev = () => props.page > 1;
  const hasNext = () => props.page * props.perPage < props.total;

  return (
    <Show when={hasPrev() || hasNext()}>
      <nav class="pagination is-centered mt-5" role="navigation" aria-label="pagination">
        <Show when={hasPrev()}>
          <a class="pagination-previous" onClick={() => props.onPageChange(props.page - 1)}
             data-l10n-id="pagination-previous" />
        </Show>
        <Show when={hasNext()}>
          <a class="pagination-next" onClick={() => props.onPageChange(props.page + 1)}
             data-l10n-id="pagination-next" />
        </Show>
      </nav>
    </Show>
  );
};

export const MapsIndexPage = () => {
  const [searchParams, setSearchParams] = useSearchParams();
  const page = () => Math.max(Number(searchParams.page || 1), 1);

  const [data] = createResource(page, async (p) => {
    const res = await fetch(`/api/v1/maps?page=${p}`);
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    return res.json() as Promise<MapsResponse>;
  });

  const handlePageChange = (newPage: number) => {
    setSearchParams({ page: newPage > 1 ? String(newPage) : "" });
    window.scrollTo({ top: 0, behavior: "smooth" });
  };

  return (
    <>
      <section class="hero">
        <div class="hero-body p-0">
          <img src={heroSrc} data-l10n-id="hero-image" style="width:100%;height:360px;object-fit:cover;object-position:bottom;display:block" />
        </div>
      </section>
      <section class="section">
        <div class="container">
          <Show when={data.loading}>
            <div class="has-text-centered py-5">
              <span class="icon"><i class="fa-solid fa-spinner fa-spin" /></span>
            </div>
          </Show>
          <Show when={data.error}>
            <div class="notification is-danger is-light" />
          </Show>
          <Show when={data()} keyed>
            {(response) => (
              <>
                <div class="columns is-multiline">
                  <For each={response.maps}>
                    {(map) => (
                      <div class="column is-half-tablet is-one-quarter-desktop">
                        <MapCard map={map} />
                      </div>
                    )}
                  </For>
                </div>
                <Pagination
                  page={response.page}
                  perPage={response.per_page}
                  total={response.total}
                  onPageChange={handlePageChange}
                />
              </>
            )}
          </Show>
        </div>
      </section>
    </>
  );
};
