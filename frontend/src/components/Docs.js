import React, { useState, useEffect } from 'react';
import ReactMarkdown from 'react-markdown';
import remarkGfm from 'remark-gfm';
import rehypeRaw from 'rehype-raw';
import rehypeHighlight from 'rehype-highlight';
import './Docs.css';
import 'highlight.js/styles/atom-one-dark.css';

const Docs = () => {
  const [selectedDoc, setSelectedDoc] = useState('intro');
  const [markdownContent, setMarkdownContent] = useState('');
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  // Documentation structure
  const docSections = {
    'Overview': [
      { id: 'intro', title: 'Introduction', file: 'intro.md' },
      { id: 'quickstart', title: 'Quick Start', file: 'quickstart.md' },
      { id: 'architecture', title: 'Architecture', file: 'architecture.md' },
      { id: 'faq', title: 'FAQ', file: 'faq.md' },
    ],
    'Protocol': [
      { id: 'WHITEPAPER', title: 'Whitepaper', file: 'WHITEPAPER.md' },
      { id: 'tokenomics', title: 'Tokenomics', file: 'tokenomics.md' },
      { id: 'protocol-overview', title: 'Protocol Overview', file: 'protocol-overview.md' },
    ],
    'Mechanisms': [
      { id: 'dynamic-apy', title: 'Dynamic APY', file: 'mechanisms/dynamic-apy.md' },
      { id: 'unstake-penalty', title: 'Unstake Penalty', file: 'mechanisms/unstake-penalty.md' },
      { id: 'instant-unstake', title: 'Instant Unstake', file: 'mechanisms/instant-unstake.md' },
      { id: 'referral-system', title: 'Referral System', file: 'mechanisms/referral-system.md' },
      { id: 'lock-tiers', title: 'Lock Tiers', file: 'mechanisms/lock-tiers.md' },
      { id: 'treasury-backing', title: 'Treasury Backing', file: 'mechanisms/treasury-backing.md' },
      { id: 'buyback-engine', title: 'Buyback Engine', file: 'mechanisms/buyback-engine.md' },
      { id: 'transfer-tax', title: 'Transfer Tax', file: 'mechanisms/transfer-tax.md' },
    ],
    'Features': [
      { id: 'staking-guide', title: 'Staking Guide', file: 'staking-guide.md' },
      { id: 'bonding-curve', title: 'Bonding Curve', file: 'bonding-curve.md' },
      { id: 'protocol-bonds', title: 'Protocol Bonds', file: 'protocol-bonds.md' },
    ],
    'Technical': [
      { id: 'mathematics', title: 'Mathematics', file: 'mathematics.md' },
      { id: 'smart-contracts', title: 'Smart Contracts', file: 'smart-contracts.md' },
      { id: 'security', title: 'Security', file: 'security.md' },
    ],
  };

  // Load markdown content when selected doc changes
  useEffect(() => {
    const loadMarkdown = async () => {
      setLoading(true);
      setError(null);

      try {
        // Find the selected document file
        let fileName = 'README.md';
        for (const section of Object.values(docSections)) {
          const doc = section.find(d => d.id === selectedDoc);
          if (doc) {
            fileName = doc.file;
            break;
          }
        }

        // Fetch the markdown file from public/docs
        const response = await fetch(`/docs/${fileName}`);

        if (!response.ok) {
          throw new Error(`Failed to load document: ${response.statusText}`);
        }

        const text = await response.text();
        setMarkdownContent(text);
      } catch (err) {
        console.error('Error loading markdown:', err);
        setError(`Failed to load documentation: ${err.message}`);
      } finally {
        setLoading(false);
      }
    };

    loadMarkdown();
  }, [selectedDoc]);

  return (
    <div className="docs-container">
      {/* Sidebar Navigation */}
      <aside className="docs-sidebar">
        <h2>Documentation</h2>
        {Object.entries(docSections).map(([sectionName, docs]) => (
          <div key={sectionName} className="docs-nav-section">
            <h3>{sectionName}</h3>
            {docs.map(doc => (
              <div
                key={doc.id}
                className={`docs-nav-item ${selectedDoc === doc.id ? 'active' : ''}`}
                onClick={() => setSelectedDoc(doc.id)}
              >
                {doc.title}
              </div>
            ))}
          </div>
        ))}
      </aside>

      {/* Main Content Area */}
      <main className="docs-content">
        <div className="docs-content-inner">
          {loading && (
            <div className="docs-loading">
              <p>Loading documentation...</p>
            </div>
          )}

          {error && (
            <div className="docs-error">
              <p>{error}</p>
            </div>
          )}

          {!loading && !error && (
            <div className="markdown-content">
              <ReactMarkdown
                remarkPlugins={[remarkGfm]}
                rehypePlugins={[rehypeRaw, rehypeHighlight]}
                components={{
                  // Custom component renderers for better styling
                  a: ({ node, ...props }) => (
                    <a {...props} target="_blank" rel="noopener noreferrer" />
                  ),
                  code: ({ node, inline, className, children, ...props }) => {
                    if (inline) {
                      return <code className={className} {...props}>{children}</code>;
                    }
                    return (
                      <code className={className} {...props}>
                        {children}
                      </code>
                    );
                  },
                }}
              >
                {markdownContent}
              </ReactMarkdown>
            </div>
          )}
        </div>
      </main>
    </div>
  );
};

export default Docs;
