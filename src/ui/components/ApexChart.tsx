import { useRef, useEffect } from 'preact/hooks';

declare const ApexCharts: any;

export function ApexChart({ options, id }: { options: any; id?: string }) {
  const ref = useRef<HTMLDivElement>(null);
  const chartRef = useRef<any>(null);

  useEffect(() => {
    if (chartRef.current) chartRef.current.destroy();
    if (ref.current && options) {
      chartRef.current = new ApexCharts(ref.current, options);
      chartRef.current.render();
    }
    return () => { chartRef.current?.destroy(); chartRef.current = null; };
  });

  return <div ref={ref} id={id} style={{ width: '100%', height: '100%' }} />;
}
