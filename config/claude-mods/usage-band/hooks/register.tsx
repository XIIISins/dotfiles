import { atom, read, update } from 'claude-code'
import type { Register, SessionUsage } from 'claude-code'

import type { Usage } from '../types'

const usage = atom({ plugin: 'usage-band', key: 'usage' } as const, null)
const branch = atom({ plugin: 'usage-band', key: 'branch' } as const, null)

// TokyoNight Moon, copied from config/palette/tokyonight-moon.palette (a plugin can't read it at runtime; keep in sync by hand)
const BG_DARK = '#1e2030'
const BG_HIGHLIGHT = '#2f334d'
const FG_GUTTER = '#3b4261'
const FG_DARK = '#828bb8'
const COMMENT = '#636da6'
const BLUE = '#82aaff'
const YELLOW = '#ffc777'
const RED = '#ff757f'

// Powerline solid arrows join the segments, which alternate backgrounds like the tmux statusline
const BRANCH = ''
const ARROW = ''
const ARROW_LEFT = ''
const SEGMENT_BG = [FG_GUTTER, BG_HIGHLIGHT]

type Part = readonly [text: string, color: string]

type Cell = { text: string; fg: string; bg?: string }

const LABELS: Record<string, string> = { five_hour: '5h', seven_day: '7d', spend_limit: 'spend' }

const WARN = 70
const CRIT = 90

const shade = (percent: number) => (percent >= CRIT ? RED : percent >= WARN ? YELLOW : BLUE)

const MIN_BAR = 3

// all the bars together take at most this share of the terminal's width
const MAX_SHARE = 1 / 3

const cells = (percent: number, bar: number) => Math.min(bar, Math.max(0, Math.round((percent / 100) * bar)))

// the number only earns its room once the bar is nearly full
const pct = (percent: number) => (percent > 80 ? ` ${Math.round(percent)}%` : '')

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

		const head = await read($, branch)

		// the context is in the line below the band, and the 7d window and the cost only matter once the 7d window warns
		const week = u.limits.find(l => l.kind === 'seven_day')
		const quiet = week === undefined || week.percentUsed < WARN
		const limits = u.limits.filter(l => l.kind !== 'seven_day' || !quiet)
		const bars = Math.max(1, limits.length)

		// every bar gets the same length: what the width leaves after the text and the branch, capped at its share
		const build = (bar: number) => {
			const gauge = (label: string, percent: number): Part[] => [
				[`${label} `, FG_DARK],
				['█'.repeat(cells(percent, bar)), shade(percent)],
				['░'.repeat(bar - cells(percent, bar)), COMMENT],
				[pct(percent), shade(percent)],
			]

			return [
				...limits.map(l => gauge(LABELS[l.kind] ?? l.kind, l.percentUsed)),
				...(u.usd === null || quiet ? [] : [[[`$${u.usd.toFixed(2)}`, FG_DARK]] as Part[]]),
			]
		}

		const fixed = build(0).reduce((n, parts) => n + parts.reduce((m, [text]) => m + text.length, 0) + 3, 0)
		const branchWidth = head === null ? 0 : Math.min(head.length, 20) + 6
		const space = Math.floor((e.props.bodyColumns - fixed - branchWidth) / bars)
		const bar = Math.max(MIN_BAR, Math.min(space, Math.floor((e.props.bodyColumns * MAX_SHARE) / bars)))
		const gauges = build(bar)

		if (gauges.length === 0 && head === null) {
			return next(e)
		}

		const left: Cell[] = gauges.flatMap((parts, i) => {
			const bg = SEGMENT_BG[i % 2]
			const last = i === gauges.length - 1
			return [
				{ text: ' ', fg: FG_DARK, bg },
				...parts.map(([text, fg]) => ({ text, fg, bg })),
				{ text: ' ', fg: FG_DARK, bg },
				{ text: ARROW, fg: bg, bg: last ? undefined : SEGMENT_BG[(i + 1) % 2] },
			]
		})

		// the branch segment sits at the right end; skipped when it has no room
		const leftWidth = left.reduce((n, { text }) => n + text.length, 0)
		const room = e.props.bodyColumns - leftWidth - 5 - 1
		const label = head === null ? '' : head.length > room ? `${head.slice(0, Math.max(0, room - 1))}…` : head
		const right: Cell[] = label === '' || room < 2
			? []
			: [
					{ text: ' '.repeat(room - label.length + 1), fg: FG_DARK },
					{ text: ARROW_LEFT, fg: BLUE },
					{ text: ` ${BRANCH} ${label} `, fg: BG_DARK, bg: BLUE },
				]

		return (
			<Box>
				{[...left, ...right].map(({ text, fg, bg }, i) => (
					<Text key={i} color={fg} backgroundColor={bg}>
						{text}
					</Text>
				))}
			</Box>
		)
	})
}
