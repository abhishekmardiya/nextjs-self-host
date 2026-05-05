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

const REQ_RES_PRODUCTS_RECORDS_BASE =
  "https://reqres.in/api/collections/products/records";
const REQ_RES_PROJECT_ID = process.env.REQ_RES_PROJECT_ID;
const REQ_RES_API_KEY = process.env.REQ_RES_API_KEY;

const getFetchConfig = (tag: string): RequestInit => {
  return {
    method: "GET",
    headers: {
      "x-api-key": REQ_RES_API_KEY ?? "",
      "X-Reqres-Env": "prod",
    },
    cache: "force-cache",
    next: { tags: [tag] },
  };
};

export const getAllRecords = async (): Promise<Record[]> => {
  const res = await fetch(
    `${REQ_RES_PRODUCTS_RECORDS_BASE}?project_id=${REQ_RES_PROJECT_ID}`,
    getFetchConfig("records"),
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
    `${REQ_RES_PRODUCTS_RECORDS_BASE}/${id}?project_id=${REQ_RES_PROJECT_ID}`,
    getFetchConfig(id),
  );

  if (!res.ok) {
    console.error(`Failed to fetch record: ${res.status} ${res.statusText}`);
    return null;
  }

  const data = await res.json();
  return data?.data;
};
