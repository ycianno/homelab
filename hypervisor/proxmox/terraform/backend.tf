terraform {
  backend "pg" {
    schema_name = "terraform_remote_state"
  }
}
