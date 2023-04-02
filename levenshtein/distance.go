package levenshtein

import "math"

// Ported from: https://github.com/crystal-lang/crystal/blob/release/1.7/src/levenshtein.cr

func Distance(first, second string) int {
	if first == second {
		return 0
	}

	slen := len(first)
	tlen := len(second)

	if slen == 0 {
		return tlen
	}
	if tlen == 0 {
		return slen
	}

	if tlen > slen {
		first, second = second, first
		_, tlen = tlen, slen
	}

	costs := make([]float64, tlen+1)
	var last float64

	for i, c1 := range first {
		last = (float64)(i) + 1

		for j, c2 := range second {
			var sub float64
			if c1 == c2 {
				sub = 0
			} else {
				sub = 1
			}

			cost := math.Min(math.Min(last+1, costs[j+1]+1), costs[j]+sub)
			costs[j] = last
			last = cost
		}

		costs[tlen] = last
	}

	return int(last)
}

type entry[T any] struct {
	value T
	dist  int
}

func SortBy[T any](target string, subjects []T, fn func(T) string) []T {
	t := int(len(target) / 5)
	var best *entry[T]
	var res []*entry[T]

	for _, s := range subjects {
		d := Distance(target, fn(s))
		if d <= t {
			if best != nil {
				if d < best.dist {
					res = append(res, best)
					best = &entry[T]{value: s, dist: d}
				}
			} else {
				best = &entry[T]{value: s, dist: d}
				res = []*entry[T]{best}
			}
		}
	}

	if best == nil {
		return []T{}
	}

	v := make([]T, len(res))
	for i, r := range res {
		v[i] = r.value
	}

	return v
}
