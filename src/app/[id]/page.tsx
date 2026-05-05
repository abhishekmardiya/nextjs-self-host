import { getRecordById } from "@/api";
import Link from "next/link";
import { notFound } from "next/navigation";
import PurgeCacheButton from "../components/PurgeCacheButton";

// export async function generateStaticParams() {
//   const records = await getAllRecords();

//   return records.map((record) => ({
//     id: record.id,
//   }));
// }

export const dynamic = "force-static";

export default async function ProductPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;

  const record = await getRecordById({ id });

  if (!record) {
    notFound();
  }

  const {
    id: recordId,
    data: { name, price, category, in_stock },
  } = record;

  return (
    <div className="flex flex-col flex-1 items-center justify-center bg-zinc-50 font-sans dark:bg-black">
      <main className="flex flex-1 w-full max-w-3xl flex-col items-center justify-center py-32 px-16 bg-white dark:bg-black sm:items-start">
        <div className="mb-6 flex w-full items-center justify-between gap-4">
          <Link
            href="/"
            className="inline-flex items-center gap-2 rounded-lg border border-zinc-200 bg-white px-3 py-2 text-sm font-medium text-zinc-900 transition-colors hover:bg-zinc-50 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-zinc-400 focus-visible:ring-offset-2 focus-visible:ring-offset-white dark:border-zinc-800 dark:bg-zinc-950 dark:text-zinc-100 dark:hover:bg-zinc-900 dark:focus-visible:ring-zinc-600 dark:focus-visible:ring-offset-black"
            prefetch={false}
          >
            <span aria-hidden="true">←</span>
            Back to home
          </Link>

          <div className="shrink-0">
            <PurgeCacheButton tag={id} />
          </div>
        </div>

        <div className="flex w-full items-start justify-between gap-6">
          <div className="min-w-0">
            <h1 className="truncate text-3xl font-semibold text-zinc-900 dark:text-zinc-100">
              {name}
            </h1>
            <div className="mt-2 flex flex-wrap items-center gap-2">
              <span className="rounded-full border border-zinc-200 bg-white px-2 py-0.5 text-xs font-medium text-zinc-700 dark:border-zinc-800 dark:bg-zinc-900 dark:text-zinc-200">
                {category}
              </span>
              <span
                className={[
                  "rounded-full px-2 py-0.5 text-xs font-semibold",
                  in_stock
                    ? "bg-emerald-100 text-emerald-900 dark:bg-emerald-950 dark:text-emerald-200"
                    : "bg-zinc-200 text-zinc-800 dark:bg-zinc-800 dark:text-zinc-200",
                ].join(" ")}
              >
                {in_stock ? "In stock" : "Out of stock"}
              </span>
            </div>
          </div>

          <div className="shrink-0 text-right">
            <div className="text-sm font-medium text-zinc-500 dark:text-zinc-400">
              Price
            </div>
            <div className="mt-1 text-lg font-semibold text-zinc-900 dark:text-zinc-100">
              ${price.toFixed(2)}
            </div>
          </div>
        </div>

        <br />
        <dt className="text-zinc-500 dark:text-zinc-400">ID</dt>
        <dd className="mt-1 truncate font-mono text-xs">{recordId}</dd>
      </main>
    </div>
  );
}
