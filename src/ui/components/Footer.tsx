/** Static footer component -- first Preact component proof of concept. */
export function Footer() {
  return (
    <footer>
      <div class="footer-content">
        <p>
          Cost estimates based on Anthropic and OpenAI API pricing (
          <a
            href="https://docs.anthropic.com/en/docs/about-claude/pricing"
            target="_blank"
            rel="noopener noreferrer"
          >
            Anthropic
          </a>
          {' '}+{' '}
          <a
            href="https://developers.openai.com/api/docs/pricing"
            target="_blank"
            rel="noopener noreferrer"
          >
            OpenAI
          </a>
          ). Local dashboard totals are estimates, not subscriber billing statements.
        </p>
        <p>
          GitHub:{' '}
          <a
            href="https://github.com/po4yka/heimdall"
            target="_blank"
            rel="noopener noreferrer"
          >
            po4yka/heimdall
          </a>{' '}
          &middot; License: MIT
        </p>
      </div>
    </footer>
  );
}
