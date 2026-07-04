import "./globals.css";

export const metadata = {
  title: "Print Union",
  description: "Turn flat flyers and posters into editable design systems."
};

export default function RootLayout({ children }) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
