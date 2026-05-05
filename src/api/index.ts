import "server-only";

interface Record {
  id: string;
  data: {
    name: string;
    price: number;
    category: string;
    in_stock: boolean;
  };
}

const getRequestInit = (tag: string): RequestInit => {
  return {
    method: "GET",
    headers: {
      "x-api-key": process.env.REQ_RES_API_KEY ?? "",
      "X-Reqres-Env": "prod",
    },
    cache: "force-cache",
    next: { tags: [tag] },
  };
};

export const getAllRecords = async (): Promise<Record[]> => {
  const res = await fetch(
    "https://reqres.in/api/collections/products/records?project_id=12257",
    getRequestInit("records"),
  );

  if (!res.ok) {
    console.error(`Failed to fetch records: ${res.status} ${res.statusText}`);
    return [];
  }

  const data = await res.json();
  return data?.data;
};

export const getRecordById = async ({
  id,
}: {
  id: string;
}): Promise<Record | null> => {
  const res = await fetch(
    `https://reqres.in/api/collections/products/records/${id}?project_id=12257`,
    getRequestInit(id),
  );

  if (!res.ok) {
    console.error(`Failed to fetch record: ${res.status} ${res.statusText}`);
    return null;
  }

  const data = await res.json();
  return data?.data;
};
