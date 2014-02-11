package main

import (
	"fmt"
	"sort"
	"strings"
	"time"

	pinyin "dbus/com/deepin/api/search"
)

var tree *pinyin.Search = nil
var treeId string

type SearchFunc func(key string, res chan<- SearchResult, end chan<- bool)

// func registerSearchFunc(searchFunc SearchFunc) {
// 	searchFuncs = append(searchFuncs, searchFunc)
// }

type SearchResult struct {
	Id    ItemId
	Score uint32
}

type Result []SearchResult

func (res Result) Len() int {
	return len(res)
}

func (res Result) Swap(i, j int) {
	res[i], res[j] = res[j], res[i]
}

func (res Result) Less(i, j int) bool {
	return !(res[i].Score < res[j].Score) ||
		itemTable[res[i].Id].Name < itemTable[res[j].Id].Name
}

// TODO:
// 1. cancellable
func search(key string) []ItemId {
	key = strings.TrimSpace(key)
	res := make(Result, 0)
	resChan := make(chan SearchResult)
	go func(r *Result, c <-chan SearchResult) {
		for {
			select {
			case d := <-c:
				*r = append(*r, d)
			case <-time.After(2 * time.Second):
				return
			}
		}
	}(&res, resChan)

	keys := []string{}
	if tree != nil {
		keys, _ = tree.SearchKeys(key, treeId)
	}

	if len(keys) == 0 {
		keys = append(keys, key)
	}

	done := make(chan bool, 1)
	for _, k := range keys {
		for _, fn := range searchFuncs {
			go fn(k, resChan, done)
		}
	}

	for _ = range keys {
		for _ = range searchFuncs {
			select {
			case <-done:
				fmt.Println("done")
			case <-time.After(1 * time.Second):
				fmt.Println("time out")
			}
		}
	}

	sort.Sort(res)

	ids := make([]ItemId, 0)
	for _, v := range res {
		// fmt.Println(itemTable[v.Id].Name, v.Score)
		ids = append(ids, v.Id)
	}
	return ids
}

// 2. add a weight for frequency.
func searchInstalled(key string, res chan<- SearchResult, end chan<- bool) {
	matchers := getMatchers(key)
	for id, v := range itemTable {
		var score uint32 = 0
		var weight uint32 = 1

		for matcher, s := range matchers {
			if matcher.MatchString(v.Name) {
				// fmt.Println(v.Name)
				score += s * weight
			}
			for _, keyword := range v.xinfo.keywords {
				if matcher.MatchString(keyword) {
					// fmt.Println(keyword)
					score += s * weight
				}
			}
			if matcher.MatchString(v.xinfo.exec) {
				// fmt.Println(v.exec)
				score += s * weight
			}
			if matcher.MatchString(v.xinfo.genericName) {
				// fmt.Println(v.genericName)
				score += s * weight
			}
			if matcher.MatchString(v.xinfo.description) {
				// fmt.Println(v.description)
				score += s * weight
			}
		}

		if score > 0 {
			res <- SearchResult{id, score}
		}
		// res <- SearchResult{id, score}
	}
	end <- true
}

var searchFuncs = []SearchFunc{
	searchInstalled,
}
