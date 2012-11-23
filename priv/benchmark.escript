#!/usr/bin/escript
%% -*- erlang -*-
%%! -pa ebin +K true +A 4 -smp enable

%%%----------------------------------------------------------------------
%%% Copyright (c) 2012 Peter Lemenkov <lemenkov@gmail.com>
%%%
%%% All rights reserved.
%%%
%%% Redistribution and use in source and binary forms, with or without modification,
%%% are permitted provided that the following conditions are met:
%%%
%%% * Redistributions of source code must retain the above copyright notice, this
%%% list of conditions and the following disclaimer.
%%% * Redistributions in binary form must reproduce the above copyright notice,
%%% this list of conditions and the following disclaimer in the documentation
%%% and/or other materials provided with the distribution.
%%% * Neither the name of the authors nor the names of its contributors
%%% may be used to endorse or promote products derived from this software
%%% without specific prior written permission.
%%%
%%% THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ''AS IS'' AND ANY
%%% EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
%%% WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
%%% DISCLAIMED. IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE FOR ANY
%%% DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
%%% (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
%%% LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
%%% ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
%%% (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
%%% SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
%%%
%%%----------------------------------------------------------------------

run_create(0, _) ->
	ok;
run_create(Number, Fd) ->
	C_U = io_lib:format("24393_4 Uc0,8,18,101 0003e30c-callid~p@192.168.0.100 192.0.43.10 27686 0003e30cc50cd69210b8c36b-0ecf0120;1~n", [Number]),
	C_L = io_lib:format("24393_4 Lc0,8,18,101 0003e30c-callid~p@192.168.0.100 192.0.43.11 19686 0003e30cc50cd69210b8c36b-0ecf0120;1 1372466422;1~n", [Number]),
	gen_udp:send(Fd, {127,0,0,1}, 33333, C_U),
	{ok, _} = gen_udp:recv(Fd, 0),
	gen_udp:send(Fd, {127,0,0,1}, 33333, C_L),
	{ok, _} = gen_udp:recv(Fd, 0),
	run_create(Number - 1, Fd).

run_destroy(0, _) ->
	ok;
run_destroy(Number, Fd) ->
%	io:format("DESTROY: ~b~n", [Number]),
	C_D = io_lib:format("24393_4 D 0003e30c-callid~p@192.168.0.100 0003e30cc50cd69210b8c36b-0ecf0120 1372466422\n", [Number]),
	gen_udp:send(Fd, {127,0,0,1}, 33333, C_D),
	{ok, _} = gen_udp:recv(Fd, 0),
	run_destroy(Number - 1, Fd).

run_create_and_destroy(0, _) ->
	ok;
run_create_and_destroy(Number, Fd) ->
	C_U = io_lib:format("24393_4 Uc0,8,18,101 0003e30c-callid~p@192.168.0.100 192.0.43.10 27686 0003e30cc50cd69210b8c36b-0ecf0120;1~n", [Number]),
	C_L = io_lib:format("24393_4 Lc0,8,18,101 0003e30c-callid~p@192.168.0.100 192.0.43.11 19686 0003e30cc50cd69210b8c36b-0ecf0120;1 1372466422;1~n", [Number]),
	C_D = io_lib:format("24393_4 D 0003e30c-callid~p@192.168.0.100 0003e30cc50cd69210b8c36b-0ecf0120 1372466422\n", [Number]),
	gen_udp:send(Fd, {127,0,0,1}, 33333, C_U),
	{ok, _} = gen_udp:recv(Fd, 0),
	gen_udp:send(Fd, {127,0,0,1}, 33333, C_L),
	{ok, _} = gen_udp:recv(Fd, 0),
	gen_udp:send(Fd, {127,0,0,1}, 33333, C_D),
	{ok, _} = gen_udp:recv(Fd, 0),
	run_create_and_destroy(Number - 1, Fd).

main(_) ->
	%%
	%% This is the socket which will be used for sending commands and receiving notifications messages
	%%

	{ok, Fd} = gen_udp:open(0, [{active, false}, binary]),

	%%
	%% Set node name
	%%

	net_kernel:start(['erlrtpproxy_benchmark@localhost', longnames]),

	%%
	%% Set necessary options
	%% (normally we'll set them in the /etc/erlrtpproxy.config
	%%

	%% Set up backend's type (SER for now)
	application:set_env(rtpproxy, backend, ser),

	%% Options for SER backend
	application:set_env(rtpproxy, listen, {udp, "127.0.0.1", 33333}),

	%% Options for notification backend
	application:set_env(rtpproxy, notify_servers, udp),
	application:set_env(rtpproxy, ignore_start, true),
	application:set_env(rtpproxy, ignore_stop, true),

	%% Options for rtpproxy itself
	application:set_env(rtpproxy, external, {127,0,0,1}),
	application:set_env(rtpproxy, ttl, 105000),

	%%
	%% Emulate starting pool of nodes
	%%

	Nodes = [node() | pool:start(rtpproxy)],

	%%
	%% Run gproc
	%%

	rpc:multicall(Nodes, application, set_env, [gproc, gproc_dist, all]),
	rpc:multicall(Nodes, application, start, [gproc]),

	%%
	%% Start rtpproxy
	%%

	application:start(rtpproxy),

	%%
	%% Warm everything up
	%%

	error_logger:tty(false),
	gen_udp:send(Fd, {127,0,0,1}, 33333, <<"592_36821 V\n">>),
	{ok, _} = gen_udp:recv(Fd, 0),
	gen_udp:send(Fd, {127,0,0,1}, 33333, <<"24393_4 Uc0,8,18,101 0003e30c-callid01@192.168.0.100 192.0.43.10 27686 0003e30cc50cd69210b8c36b-0ecf0120;1\n">>),
	{ok, _} = gen_udp:recv(Fd, 0),
	gen_udp:send(Fd, {127,0,0,1}, 33333, <<"24393_4 Lc0,8,18,101 0003e30c-callid01@192.168.0.100 192.0.43.11 19686 0003e30cc50cd69210b8c36b-0ecf0120;1 1372466422;1\n">>),
	{ok, _} = gen_udp:recv(Fd, 0),
	gen_udp:send(Fd, {127,0,0,1}, 33333, <<"24393_4 D 0003e30c-callid01@192.168.0.100 0003e30cc50cd69210b8c36b-0ecf0120 1372466422\n">>),
	{ok, _} = gen_udp:recv(Fd, 0),
	error_logger:tty(true),


	%%
	%% Benchmarking
	%%

	Number1 = 10000,
	error_logger:tty(false),
	{Time1, _} = timer:tc(fun() -> run_create_and_destroy(Number1, Fd) end),
	error_logger:tty(true),
	error_logger:info_msg("Finished creating and tearing down ~p calls in ~p seconds~n", [Number1, Time1 / 1000000]),

	Number2 = 250,
	error_logger:tty(false),
	{Time2, _} = timer:tc(fun() -> run_create(Number2, Fd) end),
	run_destroy(Number2, Fd),
	error_logger:tty(true),
	error_logger:info_msg("Finished creating ~p calls in ~p seconds~n", [Number2, Time2 / 1000000]),

	%%
	%% Tear down everything
	%%

	application:stop(rtpproxy),
	application:stop(gproc),
	net_kernel:stop(),

	gen_udp:close(Fd).

