module Endpoint = struct
  type t = Uri.t
  let to_uri t = t
  let of_uri t = t
end


module Body = Cohttp_lwt_body
module Client = Cohttp_lwt_unix.Client
module Code = Cohttp.Code 
module Response = Client.Response

type t = {
  uri : Uri.t
}

type error = 
  | No_response
  | Unexpected_response of int * int * string

type 'a response =
  | Ok of 'a
  | Error of error

let (>>=) = Lwt.bind

let create endpoint access_token =
  { uri = Uri.add_query_param' (Endpoint.to_uri endpoint)
      ("access_token", Auth.Token.to_string access_token) }
      
let error_to_string = function
  | No_response -> "The server did not return a response"
  | Unexpected_response (e, a, s) -> 
    Printf.sprintf "Expected response code %i, received code %i (%s)" e a s
      
let get_expect_200 t params path =
  Uri.add_query_params' (Uri.with_path t.uri path) params 
  |> Client.get >>= fun (resp, body) -> 
      (match (
        match resp.Response.status with
        | `Code c -> c
        | c -> Code.code_of_status c) with
      | 200 -> Body.to_string body >>= (fun b -> Ok b |> Lwt.return)
      | c -> Error (Unexpected_response (200, c, Code.reason_phrase_of_code c)) |> Lwt.return)

let post_expect_200 t params path =
  Uri.add_query_params' (Uri.with_path t.uri path) params 
  |> Client.post >>= fun (resp, body) -> 
      (match (
        match resp.Response.status with
        | `Code c -> c
        | c -> Code.code_of_status c) with
      | 200 -> Body.to_string body >>= (fun b -> Ok b |> Lwt.return)
      | c -> Error (Unexpected_response (200, c, Code.reason_phrase_of_code c)) |> Lwt.return)
      
let get_home_stream ?user_id:(user_id="me") ?since t =
  let params = match since with
  | Some v -> [("since", string_of_int v)]
  | None -> [] in
  Printf.sprintf "/%s/home" user_id 
  |> get_expect_200 t params >>= function
    | Ok body -> Ok (Types.response_of_string body) |> Lwt.return
    | Error No_response -> Error No_response |> Lwt.return
    | Error (Unexpected_response (a, b, c)) -> Error (Unexpected_response (a, b, c)) |> Lwt.return

let publish_message ?user_id:(user_id="me") t text =
  Printf.sprintf "/%s/feed" user_id 
  |> post_expect_200 t [("message", text)] >>= function
    | Ok body -> Ok (Types.publish_response_of_string body) |> Lwt.return
    | Error No_response -> Error No_response |> Lwt.return
    | Error (Unexpected_response (a, b, c)) -> Error (Unexpected_response (a, b, c)) |> Lwt.return
