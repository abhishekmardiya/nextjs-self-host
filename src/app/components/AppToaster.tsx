"use client";

import { Toaster } from "sonner";

export function AppToaster() {
  return (
    <Toaster
      richColors
      closeButton
      position="top-right"
      toastOptions={{
        duration: 3000,
        classNames: {
          description:
            "text-sm whitespace-pre-wrap text-balance max-w-[min(100vw-2rem,26rem)] leading-relaxed",
        },
      }}
    />
  );
}
