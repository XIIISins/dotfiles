export type Usage = {
	tokens: number | null
	window: number
	percent: number | null
	limits: { kind: string; percentUsed: number }[]
	usd: number | null
}

declare module 'claude-code' {
	interface PluginState {
		'usage-band': { usage: Usage | null; branch: string | null }
	}
}
