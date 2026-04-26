import { describe, expect, it } from 'vitest';
import { SegmentedProgressBar } from './SegmentedProgressBar';

// Tests match the post-migration smooth single-fill bar (see
// SegmentedProgressBar.tsx header comment). The legacy LED-segment
// geometry is gone; assertions now check the single fill child's
// width and threshold-encoded background.

describe('SegmentedProgressBar', () => {
  it('renders bounded progress with the expected accessibility contract', () => {
    const vnode = SegmentedProgressBar({
      value: 45,
      max: 90,
      segments: 10,
      status: 'warning',
      'aria-label': 'Usage',
    }) as { props: Record<string, unknown> };
    const fill = vnode.props['children'] as { props: { style: { background: string; width: string }; class?: string } };

    expect(vnode.props['role']).toBe('progressbar');
    expect(vnode.props['aria-label']).toBe('Usage');
    expect(vnode.props['aria-valuenow']).toBe(50);
    expect(fill.props.class).toBe('segmented-bar__fill');
    expect(fill.props.style.width).toBe('50%');
    expect(fill.props.style.background).toBe('var(--warning)');
  });

  it('caps overflow at 100 percent and switches to accent styling', () => {
    const vnode = SegmentedProgressBar({
      value: 15,
      max: 10,
      segments: 5,
      size: 'compact',
    }) as { props: Record<string, unknown> };
    const fill = vnode.props['children'] as { props: { style: { background: string; width: string } } };

    expect(vnode.props['class']).toContain('segmented-bar--compact');
    expect(vnode.props['aria-valuenow']).toBe(100);
    expect(fill.props.style.width).toBe('100%');
    expect(fill.props.style.background).toBe('var(--accent)');
  });
});
