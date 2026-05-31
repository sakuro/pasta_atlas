import { createContext, createSignal, useContext, For, ParentComponent } from "solid-js";

export type ToastType = "success" | "danger" | "warning" | "info";

type Toast = {
  id: number;
  message: string;
  type: ToastType;
};

type ToastContextValue = {
  showToast: (message: string, type?: ToastType) => void;
};

const ToastContext = createContext<ToastContextValue>();

let nextId = 0;
const AUTO_DISMISS_MS = 5000;

export const ToastProvider: ParentComponent = (props) => {
  const [toasts, setToasts] = createSignal<Toast[]>([]);

  const showToast = (message: string, type: ToastType = "success") => {
    const id = nextId++;
    setToasts(prev => [...prev, { id, message, type }]);
    setTimeout(() => setToasts(prev => prev.filter(t => t.id !== id)), AUTO_DISMISS_MS);
  };

  const dismiss = (id: number) => setToasts(prev => prev.filter(t => t.id !== id));

  return (
    <ToastContext.Provider value={{ showToast }}>
      {props.children}
      <div style={{ position: "fixed", top: "4rem", right: "1rem", "z-index": "9999", "pointer-events": "none" }}>
        <For each={toasts()}>
          {(toast) => (
            <div
              class={`notification is-${toast.type} is-light`}
              style={{ "margin-bottom": "0.5rem", "pointer-events": "auto" }}
            >
              <button class="delete" onClick={() => dismiss(toast.id)} />
              {toast.message}
            </div>
          )}
        </For>
      </div>
    </ToastContext.Provider>
  );
};

export const useToast = () => {
  const ctx = useContext(ToastContext);
  if (!ctx) throw new Error("useToast must be used within ToastProvider");
  return ctx;
};
