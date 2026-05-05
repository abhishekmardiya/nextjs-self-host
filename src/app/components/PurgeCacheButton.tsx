"use client";

import { purgeCache } from "@/utils/action";
import { toast } from "sonner";

type PurgeCacheButtonProps = {
  tag: string;
};

export default function PurgeCacheButton({ tag }: PurgeCacheButtonProps) {
  const handleClick = async () => {
    await purgeCache(tag);

    toast.success("Cache invalidated");
  };

  return (
    <div className="flex items-center gap-3">
      <button
        type="button"
        onClick={handleClick}
        className="cursor-pointer inline-flex items-center rounded-lg border border-red-300 bg-red-600 px-3 py-2 text-sm font-semibold text-white shadow-sm transition-colors hover:bg-red-700 disabled:cursor-not-allowed disabled:opacity-60 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-red-500 focus-visible:ring-offset-2 focus-visible:ring-offset-zinc-50 dark:border-red-900/60 dark:bg-red-600 dark:hover:bg-red-500 dark:focus-visible:ring-red-400 dark:focus-visible:ring-offset-black"
      >
        Purge cache
      </button>
    </div>
  );
}
