import { atom, read, update } from 'claude-code'
import type { Register, SessionUsage } from 'claude-code'

import type { Usage } from '../types'

const usage = atom({ plugin: 'usage-band', key: 'usage' } as const, null)
const branch = atom({ plugin: 'usage-band', key: 'branch' } as const, null)

// TokyoNight Moon, copied from config/palette/tokyonight-moon.palette (a plugin can't read it at runtime; keep in sync by hand)
const FG_GUTTER = '#3b4261'
const FG_DARK = '#828bb8'
const COMMENT = '#636da6'
const BLUE = '#82aaff'
const YELLOW = '#ffc777'
const RED = '#ff757f'

// Powerline solid arrow closes the strip, the thin one divides gauges (tmux/statusline.conf)
const BRANCH = ''
const ARROW = ''
const DIVIDER = ''

type Part = readonly [text: string, color: string]

const LABELS: Record<string, string> = { five_hour: '5h', seven_day: '7d', spend_limit: 'spend' }

const shade = (percent: number) => (percent >= 90 ? RED : percent >= 70 ? YELLOW : BLUE)

const BAR = 10

const cells = (percent: number) => Math.min(BAR, Math.max(0, Math.round((percent / 100) * BAR)))

// the number only earns its room once the bar is nearly full
const pct = (percent: number) => (percent > 80 ? ` ${Math.round(percent)}%` : '')

const compact = (n: number) => (n >= 1000 ? `${(n / 1000).toFixed(n >= 100000 ? 0 : 1)}k` : String(n))

// "" outside a repo (git exits non-zero), "HEAD" when detached
const branchName = (r: { exitCode: number; stdout: string }) => {
	const name = r.stdout.trim()
	return r.exitCode === 0 && name !== '' ? name : null
}

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
		const head = branchName(await $.process.run(['git', 'rev-parse', '--abbrev-ref', 'HEAD']))
		await update($, branch, () => head)
		return next(e)
	})

	on('turn.complete', async ($, e, next) => {
		const head = branchName(await $.process.run(['git', 'rev-parse', '--abbrev-ref', 'HEAD']))
		await update($, branch, () => head)
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

		const gauge = (label: string, percent: number, extra = ''): Part[] => [
			[`${label} `, FG_DARK],
			['█'.repeat(cells(percent)), shade(percent)],
			['░'.repeat(BAR - cells(percent)), COMMENT],
			[pct(percent), shade(percent)],
			[extra, FG_DARK],
		]

		const gauges = [
			gauge('ctx', u.percent ?? 0, ` ${tokens}`),
			...u.limits.map(l => gauge(LABELS[l.kind] ?? l.kind, l.percentUsed)),
			...(u.usd === null ? [] : [[[`$${u.usd.toFixed(2)}`, FG_DARK]] as Part[]]),
		]

		const left: Part[] = gauges.flatMap((parts, i) => [
			...(i === 0 ? [[' ', FG_DARK] as Part] : [[` ${DIVIDER} `, COMMENT] as Part]),
			...parts,
		]).concat([[' ', FG_DARK]])

		// the branch sits at the right end, padded out to the arrow; skipped when it has no room
		const head = await read($, branch)
		const leftWidth = left.reduce((n, [text]) => n + text.length, 0)
		const room = e.props.bodyColumns - leftWidth - 1 - 3
		const label = head === null ? '' : head.length > room ? `${head.slice(0, Math.max(0, room - 1))}…` : head
		const right: Part[] = label === '' || room < 2
			? []
			: [
					[' '.repeat(e.props.bodyColumns - leftWidth - label.length - 3 - 1), FG_DARK],
					[`${BRANCH} ${label} `, FG_DARK],
				]

		return (
			<Box>
				{[...left, ...right].map(([text, color], i) => (
					<Text key={i} color={color} backgroundColor={FG_GUTTER}>
						{text}
					</Text>
				))}
				<Text color={FG_GUTTER}>{ARROW}</Text>
			</Box>
		)
	})
}
