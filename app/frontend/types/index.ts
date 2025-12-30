export interface Flash {
  alert?: string
  notice?: string
}

export interface SharedData {
  flash: Flash
  [key: string]: unknown
}
