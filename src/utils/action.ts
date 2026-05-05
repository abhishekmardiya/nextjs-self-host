"use server";

import { revalidateTag } from "next/cache";

export const purgeCache = async (tag: string) => {
  revalidateTag(encodeURIComponent(tag), "max");
};
