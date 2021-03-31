variable "emails" {
  description = "List of emails to subscribe"
  type = list(string)
}

variable "sms_phone_numbers" {
  description = "List of phone numbers to send SMS messages. Must use format like this +1 206 555 1010."
  type = list(string)
}
