import "./globals.css";
import { Toaster } from "react-hot-toast";

import Providers from "../components/Providers";

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body>
        <Toaster position="top-center" />
        <Providers>{children}</Providers>
      </body>
    </html>
  );
}
