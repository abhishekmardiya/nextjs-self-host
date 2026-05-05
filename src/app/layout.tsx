import type { Metadata } from "next";
import { Geist } from "next/font/google";
import { AppToaster } from "./components/AppToaster";
import "./globals.css";

const geistSans = Geist({
  variable: "--font-geist-sans",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  title: "Next.js Self Host",
  description: "Next.js Self Host",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" className={`${geistSans.variable} h-full antialiased`}>
      <body>
        {children}
        <AppToaster />
      </body>
    </html>
  );
}
