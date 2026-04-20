import { useEffect, useRef, useState, useCallback } from "react";
import { Terminal as XTerm } from "@xterm/xterm";
import { FitAddon } from "@xterm/addon-fit";
import { WebLinksAddon } from "@xterm/addon-web-links";
import { invoke } from "@tauri-apps/api/core";
import { listen } from "@tauri-apps/api/event";
import "@xterm/xterm/css/xterm.css";

interface TerminalProps {
  env?: Record<string, string>;
  cwd?: string;
}

export default function Terminal({ env, cwd }: TerminalProps) {
  const terminalRef = useRef<HTMLDivElement>(null);
  const xtermRef = useRef<XTerm | null>(null);
  const fitAddonRef = useRef<FitAddon | null>(null);
  const sessionIdRef = useRef<number | null>(null);
  const [isConnected, setIsConnected] = useState(false);

  const initTerminal = useCallback(async () => {
    if (!terminalRef.current || xtermRef.current) return;

    const xterm = new XTerm({
      cursorBlink: true,
      fontSize: 14,
      fontFamily: 'Menlo, Monaco, "Courier New", monospace',
      theme: {
        background: "#1a1a2e",
        foreground: "#eaeaea",
        cursor: "#f0f0f0",
        selectionBackground: "#3d3d5c",
        black: "#1a1a2e",
        red: "#ff6b6b",
        green: "#4ecdc4",
        yellow: "#ffe66d",
        blue: "#4dabf7",
        magenta: "#da77f2",
        cyan: "#66d9ef",
        white: "#eaeaea",
        brightBlack: "#4a4a6a",
        brightRed: "#ff8787",
        brightGreen: "#69db7c",
        brightYellow: "#fff3bf",
        brightBlue: "#74c0fc",
        brightMagenta: "#e599f7",
        brightCyan: "#99f6e4",
        brightWhite: "#ffffff",
      },
    });

    const fitAddon = new FitAddon();
    const webLinksAddon = new WebLinksAddon();

    xterm.loadAddon(fitAddon);
    xterm.loadAddon(webLinksAddon);
    xterm.open(terminalRef.current);

    xtermRef.current = xterm;
    fitAddonRef.current = fitAddon;

    // Fit terminal to container
    fitAddon.fit();

    // Spawn PTY
    try {
      const sessionId = await invoke<number>("spawn_pty", {
        cwd: cwd || undefined,
        env: env || undefined,
        cols: xterm.cols,
        rows: xterm.rows,
      });

      sessionIdRef.current = sessionId;
      setIsConnected(true);

      // Listen for PTY output
      const unlistenOutput = await listen<string>(
        `pty-output-${sessionId}`,
        (event) => {
          xterm.write(event.payload);
        }
      );

      // Listen for PTY exit
      const unlistenExit = await listen(`pty-exit-${sessionId}`, () => {
        xterm.write("\r\n\x1b[33m[Process exited]\x1b[0m\r\n");
        setIsConnected(false);
      });

      // Handle user input
      xterm.onData((data) => {
        if (sessionIdRef.current !== null) {
          invoke("write_pty", {
            sessionId: sessionIdRef.current,
            data,
          });
        }
      });

      // Store cleanup functions
      (xterm as any)._unlistenOutput = unlistenOutput;
      (xterm as any)._unlistenExit = unlistenExit;
    } catch (error) {
      xterm.write(`\x1b[31mFailed to start terminal: ${error}\x1b[0m\r\n`);
    }
  }, [env, cwd]);

  useEffect(() => {
    initTerminal();

    return () => {
      if (xtermRef.current) {
        const xterm = xtermRef.current as any;
        if (xterm._unlistenOutput) xterm._unlistenOutput();
        if (xterm._unlistenExit) xterm._unlistenExit();
        xtermRef.current.dispose();
        xtermRef.current = null;
      }

      if (sessionIdRef.current !== null) {
        invoke("close_pty", { sessionId: sessionIdRef.current });
        sessionIdRef.current = null;
      }
    };
  }, [initTerminal]);

  // Handle resize
  useEffect(() => {
    const handleResize = () => {
      if (fitAddonRef.current && xtermRef.current) {
        fitAddonRef.current.fit();

        if (sessionIdRef.current !== null) {
          invoke("resize_pty", {
            sessionId: sessionIdRef.current,
            cols: xtermRef.current.cols,
            rows: xtermRef.current.rows,
          });
        }
      }
    };

    window.addEventListener("resize", handleResize);

    // Initial fit after a short delay
    const timer = setTimeout(handleResize, 100);

    return () => {
      window.removeEventListener("resize", handleResize);
      clearTimeout(timer);
    };
  }, []);

  return (
    <div className="flex flex-col h-full">
      <div
        ref={terminalRef}
        className="flex-1 bg-[#1a1a2e] rounded-lg overflow-hidden"
      />
      <div className="flex items-center justify-between px-3 py-1 text-xs text-gray-400 bg-[#12121f]">
        <span>
          {isConnected ? (
            <span className="text-green-400">● Connected</span>
          ) : (
            <span className="text-yellow-400">● Disconnected</span>
          )}
        </span>
        <span>Press ⌘+K to clear</span>
      </div>
    </div>
  );
}
