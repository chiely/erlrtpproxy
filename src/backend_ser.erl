%% Copyright (c) 2011 Peter Lemenkov.
%%
%% The MIT License
%%
%% Permission is hereby granted, free of charge, to any person obtaining a copy
%% of this software and associated documentation files (the "Software"), to deal
%% in the Software without restriction, including without limitation the rights
%% to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
%% copies of the Software, and to permit persons to whom the Software is
%% furnished to do so, subject to the following conditions:
%%
%% The above copyright notice and this permission notice shall be included in
%% all copies or substantial portions of the Software.
%%
%% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
%% IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
%% FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
%% AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
%% LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
%% OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
%% THE SOFTWARE.
%%

-module(backend_ser).
-author('lemenkov@gmail.com').

-behaviour(gen_server).

-export([start_link/0]).
-export([init/1]).
-export([handle_call/3]).
-export([handle_cast/2]).
-export([handle_info/2]).
-export([code_change/3]).
-export([terminate/2]).

-include("common.hrl").

start_link() ->
	gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

init (_) ->
	process_flag(trap_exit, true),
	error_logger:info_msg("SER backend: started at ~p~n", [node()]),
	{ok, []}.

handle_call(Call, _From, State) ->
	error_logger:error_msg("SER backend: strange call: ~p~n", [Call]),
	{stop, {error, {unknown_call, Call}}, State}.

handle_cast({reply, Cmd = #cmd{origin = #origin{type = ser, ip = Ip, port = Port}}, {Addr1, Addr2}}, State) ->
	error_logger:info_msg("SER backend: reply ~p~n", [{Addr1, Addr2}]),
	Data = ser_proto:encode(#response{cookie = Cmd#cmd.cookie, origin = Cmd#cmd.origin, type = reply, data = {Addr1, Addr2}}),
	gen_server:cast(listener, {msg, Data, Ip, Port}),
	{noreply, State};

handle_cast({msg, Msg, Ip, Port}, State) ->
	try ser_proto:decode(Msg) of
		#cmd{cookie = Cookie, origin = Origin, type = ?CMD_V} ->
			% Request basic supported rtpproxy protocol version
			% see available versions here:
			% http://sippy.git.sourceforge.net/git/gitweb.cgi?p=sippy/rtpproxy;a=blob;f=rtpp_command.c#l58
			% We provide only basic functionality, currently.
			error_logger:info_msg("SER backend: cmd V~n"),
			Data = ser_proto:encode(#response{cookie = Cookie, origin = Origin, type = reply, data = {version, <<"20040107">>}}),
			gen_server:cast(listener, {msg, Data, Ip, Port});
		#cmd{cookie = Cookie, origin = Origin, type = ?CMD_VF, params=Version} ->
			% Request additional rtpproxy protocol extensions
			error_logger:info_msg("SER backend: cmd VF: ~s~n", [Version]),
			Data = ser_proto:encode(#response{cookie = Cookie, origin = Origin, type = reply, data = supported}),
			gen_server:cast(listener, {msg, Data, Ip, Port});
		#cmd{origin = Origin, type = ?CMD_L} = Cmd ->
			error_logger:info_msg("SER backend: cmd: ~p~n", [Cmd]),
			rtpproxy_ctl:command(Cmd#cmd{origin = Origin#origin{ip=Ip, port=Port}, type = ?CMD_U});
		#cmd{origin = Origin, type = ?CMD_U} = Cmd ->
			error_logger:info_msg("SER backend: cmd: ~p~n", [Cmd]),
			NotifyParams = proplists:get_value(notify, Cmd#cmd.params),
			case NotifyParams of
				undefined ->
					rtpproxy_ctl:command(Cmd#cmd{origin = Origin#origin{ip=Ip, port=Port}});
				_ ->
					case proplists:get_value(addr, NotifyParams) of
						{_,_} ->
							rtpproxy_ctl:command(Cmd#cmd{origin = Origin#origin{ip=Ip, port=Port}});
						P when is_integer(P) ->
							NotifyTag = proplists:get_value(tag, NotifyParams),
							% Assume that the IP is the same as the origin of command
							NewNotifyParams = [{notify, [{addr, {Ip, P}}, {tag, NotifyTag}]}],
							NewParams = proplists:delete(notify, Cmd#cmd.params) ++ NewNotifyParams,
							rtpproxy_ctl:command(Cmd#cmd{origin = Origin#origin{ip=Ip, port=Port}, params = NewParams})
					end
			end;
		#cmd{cookie = Cookie, origin = Origin} = Cmd ->
			error_logger:info_msg("SER backend: cmd: ~p~n", [Cmd]),
			Ret =  rtpproxy_ctl:command(Cmd#cmd{origin = Origin#origin{ip=Ip, port=Port}}),
			case Ret of
				{ok, {stats, Number}} ->
					error_logger:info_msg("SER backend: reply stats (short)~n"),
					Data = ser_proto:encode(#response{cookie = Cookie, origin = Origin, type = reply, data = Ret}),
					gen_server:cast(listener, {msg, Data, Ip, Port});
				{ok, {stats, NumberTotal, NumberActive}} ->
					error_logger:info_msg("SER backend: reply stats (full)~n"),
					Data = ser_proto:encode(#response{cookie = Cookie, origin = Origin, type = reply, data = {ok, {stats, NumberTotal, NumberActive}}}),
					gen_server:cast(listener, {msg, Data, Ip, Port});
				ok ->
					error_logger:info_msg("SER backend: reply ok (~p)~n", [Cmd]),
					Data = ser_proto:encode(#response{cookie = Cookie, origin = Origin, type = reply, data = ok}),
					gen_server:cast(listener, {msg, Data, Ip, Port});
				{error, notfound} ->
					error_logger:info_msg("SER backend: reply {error, notfound) (~p)~n", [Cmd]),
					Data = ser_proto:encode(#response{cookie = Cookie, origin = Origin, type = error, data = notfound}),
					gen_server:cast(listener, {msg, Data, Ip, Port});
				_ ->
					error_logger:info_msg("SER backend: cmd RET: ~p~n", [Ret])
			end
	catch
		throw:{error_syntax, ErrorMsg} when is_list(ErrorMsg) ->
			error_logger:error_msg("SER backend: error bad syntax. [~s -> ~s]~n", [Msg, ErrorMsg]),
			Data = ser_proto:encode({error, syntax, Msg}),
			gen_server:cast(listener, {msg, Data, Ip, Port});
		throw:{error_syntax, {ErrorMsg, ErrorData}} when is_list(ErrorMsg) ->
			error_logger:error_msg("SER backend: error bad syntax. [~s -> ~s==~p]~n", [Msg, ErrorMsg, ErrorData]),
			Data = ser_proto:encode({error, syntax, Msg}),
			gen_server:cast(listener, {msg, Data, Ip, Port});
		E:C ->
			error_logger:error_msg("SER backend: error exception. [~s -> ~p:~p]~n", [Msg, E, C]),
			Data = ser_proto:encode({error, syntax, Msg}),
			gen_server:cast(listener, {msg, Data, Ip, Port})
	end,
	{noreply, State};

handle_cast(Cast, State) ->
	error_logger:error_msg("SER backend: strange cast: ~p~n", [Cast]),
	{stop, {error, {unknown_cast, Cast}}, State}.

handle_info(Info, State) ->
	error_logger:error_msg("SER backend: strange info: ~p~n", [Info]),
	{stop, {error, {unknown_info, Info}}, State}.

code_change(_OldVsn, State, _Extra) ->
	{ok, State}.

terminate(Reason, _) ->
	{memory, Bytes} = erlang:process_info(self(), memory),
	error_logger:info_msg("SER backend: terminated due to reason [~p] (allocated ~b bytes)", [Reason, Bytes]).
