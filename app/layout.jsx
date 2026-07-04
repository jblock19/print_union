import "./globals.css";

export const metadata = {
  title: "Community Flyer MVP",
  description: "A modular community flyer editor prototype."
};

export default function RootLayout({ children }) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
