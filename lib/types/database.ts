export interface Database {
  public: {
    Tables: {
      system_config: {
        Row: {
          id: string
          organization_name: string
          city: string | null
          state: string | null
          logo_url: string | null
          primary_color: string
          secondary_color: string
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          organization_name: string
          city?: string | null
          state?: string | null
          logo_url?: string | null
          primary_color?: string
          secondary_color?: string
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          organization_name?: string
          city?: string | null
          state?: string | null
          logo_url?: string | null
          primary_color?: string
          secondary_color?: string
          created_at?: string
          updated_at?: string
        }
      }
      users: {
        Row: {
          id: string
          email: string
          name: string
          role: 'admin' | 'operator' | 'driver'
          avatar_url: string | null
          phone: string | null
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          email: string
          name: string
          role?: 'admin' | 'operator' | 'driver'
          avatar_url?: string | null
          phone?: string | null
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          email?: string
          name?: string
          role?: 'admin' | 'operator' | 'driver'
          avatar_url?: string | null
          phone?: string | null
          created_at?: string
          updated_at?: string
        }
      }
      drivers: {
        Row: {
          id: string
          name: string
          phone: string | null
          license_number: string | null
          license_expiry: string | null
          status: 'available' | 'unavailable'
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          name: string
          phone?: string | null
          license_number?: string | null
          license_expiry?: string | null
          status?: 'available' | 'unavailable'
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          name?: string
          phone?: string | null
          license_number?: string | null
          license_expiry?: string | null
          status?: 'available' | 'unavailable'
          created_at?: string
          updated_at?: string
        }
      }
      vehicles: {
        Row: {
          id: string
          license_plate: string
          model: string
          type: string
          current_mileage: number
          internal_id: string | null
          status: 'available' | 'maintenance'
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          license_plate: string
          model: string
          type: string
          current_mileage?: number
          internal_id?: string | null
          status?: 'available' | 'maintenance'
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          license_plate?: string
          model?: string
          type?: string
          current_mileage?: number
          internal_id?: string | null
          status?: 'available' | 'maintenance'
          created_at?: string
          updated_at?: string
        }
      }
      trips: {
        Row: {
          id: string
          driver_id: string | null
          vehicle_id: string | null
          scheduler_id: string | null
          trip_date: string
          departure_time: string | null
          departure_mileage: number | null
          arrival_time: string | null
          arrival_mileage: number | null
          notes: string | null
          status: 'scheduled' | 'in_progress' | 'completed' | 'cancelled'
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          driver_id?: string | null
          vehicle_id?: string | null
          scheduler_id?: string | null
          trip_date: string
          departure_time?: string | null
          departure_mileage?: number | null
          arrival_time?: string | null
          arrival_mileage?: number | null
          notes?: string | null
          status?: 'scheduled' | 'in_progress' | 'completed' | 'cancelled'
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          driver_id?: string | null
          vehicle_id?: string | null
          scheduler_id?: string | null
          trip_date?: string
          departure_time?: string | null
          departure_mileage?: number | null
          arrival_time?: string | null
          arrival_mileage?: number | null
          notes?: string | null
          status?: 'scheduled' | 'in_progress' | 'completed' | 'cancelled'
          created_at?: string
          updated_at?: string
        }
      }
      passengers: {
        Row: {
          id: string
          trip_id: string
          name: string
          document: string | null
          created_at: string
        }
        Insert: {
          id?: string
          trip_id: string
          name: string
          document?: string | null
          created_at?: string
        }
        Update: {
          id?: string
          trip_id?: string
          name?: string
          document?: string | null
          created_at?: string
        }
      }
      fuel_records: {
        Row: {
          id: string
          trip_id: string | null
          driver_id: string | null
          vehicle_id: string | null
          fuel_date: string
          location: string
          fuel_type: string
          liters: number
          total_amount: number
          mileage: number | null
          receipt_url: string | null
          created_at: string
        }
        Insert: {
          id?: string
          trip_id?: string | null
          driver_id?: string | null
          vehicle_id?: string | null
          fuel_date: string
          location: string
          fuel_type: string
          liters: number
          total_amount: number
          mileage?: number | null
          receipt_url?: string | null
          created_at?: string
        }
        Update: {
          id?: string
          trip_id?: string | null
          driver_id?: string | null
          vehicle_id?: string | null
          fuel_date?: string
          location?: string
          fuel_type?: string
          liters?: number
          total_amount?: number
          mileage?: number | null
          receipt_url?: string | null
          created_at?: string
        }
      }
      maintenance_reminders: {
        Row: {
          id: string
          vehicle_id: string
          type: string
          due_date: string | null
          due_mileage: number | null
          description: string | null
          status: 'open' | 'completed' | 'cancelled'
          completion_date: string | null
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          vehicle_id: string
          type: string
          due_date?: string | null
          due_mileage?: number | null
          description?: string | null
          status?: 'open' | 'completed' | 'cancelled'
          completion_date?: string | null
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          vehicle_id?: string
          type?: string
          due_date?: string | null
          due_mileage?: number | null
          description?: string | null
          status?: 'open' | 'completed' | 'cancelled'
          completion_date?: string | null
          created_at?: string
          updated_at?: string
        }
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      [_ in never]: never
    }
    Enums: {
      [_ in never]: never
    }
  }
}