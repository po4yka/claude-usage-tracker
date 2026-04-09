/** Static footer component -- first Preact component proof of concept. */
export function Footer() {
  return (
    <footer>
      <div class="footer-content">
        <p>
          Cost estimates based on Anthropic API pricing (
          <a
            href="https://docs.anthropic.com/en/docs/about-claude/pricing"
            target="_blank"
            rel="noopener noreferrer"
          >
            docs.anthropic.com/pricing
          </a>
          ). Actual costs for Max/Pro subscribers differ.
        </p>
        <p>
          GitHub:{' '}
          <a
            href="https://github.com/po4yka/claude-usage-tracker"
            target="_blank"
            rel="noopener noreferrer"
          >
            po4yka/claude-usage-tracker
          </a>{' '}
          &middot; License: MIT
        </p>
      </div>
    </footer>
  );
}
