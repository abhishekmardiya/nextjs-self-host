import { getAllRecords } from "@/api";
import Link from "next/link";
import PurgeCacheButton from "./components/PurgeCacheButton";

export default async function Home() {
  const records = await getAllRecords();

  if (!records.length) {
    return (
      <div className="flex flex-col flex-1 items-center justify-center bg-zinc-50 font-sans dark:bg-black">
        <main className="flex flex-1 w-full max-w-3xl flex-col items-center justify-center py-32 px-16 bg-white dark:bg-black sm:items-start">
          <h1 className="text-xl font-semibold text-zinc-900 dark:text-zinc-100">
            No records yet
          </h1>

          <div className="mt-6">
            <PurgeCacheButton tag="records" />
          </div>
        </main>
      </div>
    );
  }

  return (
    <div className="flex flex-col flex-1 items-center justify-center bg-zinc-50 font-sans dark:bg-black">
      <main className="flex flex-1 w-full max-w-3xl flex-col items-center justify-between py-32 px-16 bg-white dark:bg-black sm:items-start">
        <div className="flex w-full items-start justify-between gap-6">
          <h1 className="text-xl font-semibold text-zinc-900 dark:text-zinc-100">
            Records
          </h1>

          <div className="shrink-0">
            <PurgeCacheButton tag="records" />
          </div>
        </div>

        <ul className="mt-6 w-full space-y-2">
          {records.map(({ id, data }) => {
            const { name, price, category, in_stock } = data;

            return (
              <li key={id}>
                <div className="flex items-center justify-between gap-4 rounded-lg border border-zinc-200 bg-zinc-50 px-4 py-3 text-zinc-900 dark:border-zinc-800 dark:bg-zinc-950 dark:text-zinc-100">
                  <div className="min-w-0">
                    <div className="flex items-center gap-2">
                      <span className="truncate font-medium">{name}</span>
                      <span className="shrink-0 rounded-full border border-zinc-200 bg-white px-2 py-0.5 text-xs font-medium text-zinc-700 dark:border-zinc-800 dark:bg-zinc-900 dark:text-zinc-200">
                        {category}
                      </span>
                    </div>
                    <div className="mt-1 text-sm text-zinc-600 dark:text-zinc-400">
                      ${price.toFixed(2)}
                    </div>
                    <div className="mt-1 truncate font-mono text-xs text-zinc-500 dark:text-zinc-400">
                      {id}
                    </div>
                  </div>

                  <div className="flex shrink-0 items-center gap-3">
                    <span
                      className={[
                        "shrink-0 rounded-full px-2 py-0.5 text-xs font-semibold",
                        in_stock
                          ? "bg-emerald-100 text-emerald-900 dark:bg-emerald-950 dark:text-emerald-200"
                          : "bg-zinc-200 text-zinc-800 dark:bg-zinc-800 dark:text-zinc-200",
                      ].join(" ")}
                    >
                      {in_stock ? "In stock" : "Out of stock"}
                    </span>

                    <Link
                      href={`/${id}`}
                      className="inline-flex items-center rounded-lg border border-zinc-200 bg-white px-3 py-2 text-sm font-medium text-zinc-900 transition-colors hover:bg-zinc-50 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-zinc-400 focus-visible:ring-offset-2 focus-visible:ring-offset-zinc-50 dark:border-zinc-800 dark:bg-zinc-900 dark:text-zinc-100 dark:hover:bg-zinc-800 dark:focus-visible:ring-zinc-600 dark:focus-visible:ring-offset-black"
                      prefetch={false}
                    >
                      View details
                    </Link>
                  </div>
                </div>
              </li>
            );
          })}
        </ul>
      </main>
    </div>
  );
}
