import { atom, read, update } from 'claude-code'
import type { Register, SessionUsage } from 'claude-code'

import type { Usage } from '../types'

const usage = atom({ plugin: 'usage-band', key: 'usage' } as const, null)

// TokyoNight Moon
const FG_DARK = '#828bb8'
const COMMENT = '#636da6'
const BLUE = '#82aaff'
const YELLOW = '#ffc777'
const RED = '#ff757f'

const LABELS: Record<string, string> = { five_hour: '5h', seven_day: '7d', spend_limit: 'spend' }

const shade = (percent: number) => (percent >= 90 ? RED : percent >= 70 ? YELLOW : BLUE)

const BAR = 10

const cells = (percent: number) => Math.min(BAR, Math.max(0, Math.round((percent / 100) * BAR)))

// the number only earns its room once the bar is nearly full
const pct = (percent: number) => (percent > 80 ? ` ${Math.round(percent)}%` : '')

const compact = (n: number) => (n >= 1000 ? `${(n / 1000).toFixed(n >= 100000 ? 0 : 1)}k` : String(n))

const toUsage = ({ context, rateLimits, cost }: Pick<SessionUsage, 'context' | 'rateLimits' | 'cost'>): Usage => ({
	tokens: context.tokens ?? null,
	window: context.window,
	percent: context.percent ?? null,
	limits: rateLimits.map(r => ({ kind: r.kind, percentUsed: r.percentUsed })),
	usd: cost?.usd ?? null,
})

export const register: Register = on => {
	on('session.start', async ($, e, next) => {
		const current = toUsage(await $.session.usage())
		await update($, usage, () => current)
		return next(e)
	})

	on('session.measure', async ($, e, next) => {
		const current = toUsage(e)
		await update($, usage, () => current)
		return next(e)
	})

	on('ui.render', { component: 'AbovePrompt' }, async ($, e, next) => {
		const u = await read($, usage)

		if (e.props.hasSurvey || u === null) {
			return next(e)
		}

		const { Box, Text } = $.ui.resolve(e)
		const tokens = u.tokens === null ? '--' : `${compact(u.tokens)}/${compact(u.window)}`
		const ctx = u.percent ?? 0

		const gauge = (key: string, label: string, percent: number) => (
			<Text key={key}>
				<Text color={FG_DARK}>{label}</Text>
				<Text color={shade(percent)}>{'█'.repeat(cells(percent))}</Text>
				<Text color={COMMENT}>{'░'.repeat(BAR - cells(percent))}</Text>
				<Text color={shade(percent)}>{pct(percent)}</Text>
			</Text>
		)

		return (
			<Box>
				{gauge('ctx', 'ctx ', ctx)}
				<Text color={FG_DARK}>{` ${tokens}`}</Text>
				{u.limits.map(l => gauge(l.kind, `  ${LABELS[l.kind] ?? l.kind} `, l.percentUsed))}
				{u.usd === null ? null : <Text color={FG_DARK}>{`  $${u.usd.toFixed(2)}`}</Text>}
			</Box>
		)
	})
}
