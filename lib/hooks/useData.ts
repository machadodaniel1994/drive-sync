'use client'

import { useState, useEffect } from 'react'
import { supabase } from '@/lib/supabase'

export function useData<T>(
  table: string,
  select: string = '*',
  dependencies: any[] = []
) {
  const [data, setData] = useState<T[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    const fetchData = async () => {
      try {
        setLoading(true)
        setError(null)
        
        const { data: result, error: fetchError } = await supabase
          .from(table)
          .select(select)

        if (fetchError) {
          throw fetchError
        }

        setData(result || [])
      } catch (err) {
        console.error(`Error fetching data from ${table}:`, err)
        setError(err instanceof Error ? err.message : 'Unknown error')
      } finally {
        setLoading(false)
      }
    }

    fetchData()
  }, [table, select, ...dependencies])

  const refetch = async () => {
    await fetchData()
  }

  return { data, loading, error, refetch }
}