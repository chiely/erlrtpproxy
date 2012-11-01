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

-module(ser_proto_test).

%%
%% Tests
%%

-include_lib("eunit/include/eunit.hrl").

-include("../include/common.hrl").

cmd_v_test_() ->
	Cmd = #cmd{
			type = ?CMD_V,
			cookie = <<"24390_0">>,
			origin = #origin{type = ser, pid = self()}
		},
	CmdBin = <<"24390_0 V\n">>,
	[
		{"decoding from binary",
			fun() -> ?assertEqual(Cmd, ser_proto:decode(CmdBin)) end
		},
		{"encoding to binary",
			fun() -> ?assertEqual(CmdBin, ser_proto:encode(Cmd)) end
		}
	].

cmd_vf_test_() ->
	Cmd = #cmd{
			type = ?CMD_VF,
			cookie = <<"24393_1">>,
			origin = #origin{type = ser, pid = self()},
			params = <<"20050322">>
		},
	CmdBin = <<"24393_1 VF 20050322\n">>,
	[
		{"decoding from binary",
			fun() -> ?assertEqual(Cmd, ser_proto:decode(CmdBin)) end
		},
		{"encoding to binary",
			fun() -> ?assertEqual(CmdBin, ser_proto:encode(Cmd)) end
		},
		{"unknown version (from binary)",
			fun() -> ?assertThrow(
						{error_syntax, "Unknown version: 20070101"},
						ser_proto:decode(<<"24393_1 VF 20070101">>))
			end
		}
	].

parse_cmd_u_1_test() ->
	?assertEqual(
		#cmd{
			type = ?CMD_U,
			cookie = <<"24393_4">>,
			origin = #origin{type = ser, pid = self()},
			callid = <<"0003e30c-c50c00f7-123e8bd9-542f2edf@192.168.0.100">>,
			mediaid = <<"1">>,
			from = #party{tag = <<"0003e30cc50cd69210b8c36b-0ecf0120">>, addr = {{192,0,43,10}, 27686}, rtcpaddr = {{192,0,43,10}, 27687}},
			params = [
				{codecs, [
						{'PCMU',8000,1},
						{'PCMA',8000,1},
						{'G729',8000,1},
						101
					]
				},
				{direction, {external, external}},
				{symmetric, true}
			]
		}, ser_proto:decode(<<"24393_4 Uc0,8,18,101 0003e30c-c50c00f7-123e8bd9-542f2edf@192.168.0.100 192.0.43.10 27686 0003e30cc50cd69210b8c36b-0ecf0120;1">>)).

parse_cmd_u_2_test() ->
	?assertEqual(
		#cmd{
			type = ?CMD_U,
			cookie = <<"438_41061">>,
			origin = #origin{type = ser, pid = self()},
			callid = <<"e12ea248-94a5e885@192.168.5.3">>,
			mediaid = <<"1">>,
			from = #party{tag = <<"6b0a8f6cfc543db1o1">>, addr = {{192,0,43,9}, 16432}, rtcpaddr = {{192,0,43,9}, 16433}},
			params = [
				{codecs, [
						{'PCMA',8000,1},
						{'PCMU',8000,1},
						2,
						{'G723',8000,1},
						{'G729',8000,1},
						96,
						97,
						98,
						100,
						101
					]
				},
				{direction, {external, external}},
				{symmetric, true}
			]
		}, ser_proto:decode(<<"438_41061 Uc8,0,2,4,18,96,97,98,100,101 e12ea248-94a5e885@192.168.5.3 192.0.43.9 16432 6b0a8f6cfc543db1o1;1">>)).

parse_cmd_u_3_1_transcode_test() ->
	?assertEqual(
		#cmd{
			type = ?CMD_U,
			cookie = <<"438_41061">>,
			origin = #origin{type = ser, pid = self()},
			callid = <<"e12ea248-94a5e885@192.168.5.3">>,
			mediaid = <<"1">>,
			from = #party{tag = <<"6b0a8f6cfc543db1o1">>, addr = {{192,0,43,3}, 16432}, rtcpaddr = {{192,0,43,3}, 16433}},
			params = [
				{codecs, [
						{'PCMA',8000,1},
						{'PCMU',8000,1},
						2,
						{'G723',8000,1},
						{'G729',8000,1},
						96,
						97,
						98,
						100,
						101
					]
				},
				{direction, {external, external}},
				{symmetric, true},
				{transcode, {'G723',8000,1}}
			]
		}, ser_proto:decode(<<"438_41061 Uc8,0,2,4,18,96,97,98,100,101t4 e12ea248-94a5e885@192.168.5.3 192.0.43.3 16432 6b0a8f6cfc543db1o1;1">>)).

parse_cmd_u_3_2_transcode_test() ->
	?assertEqual(
		#cmd{
			type = ?CMD_U,
			cookie = <<"438_41061">>,
			origin = #origin{type = ser, pid = self()},
			callid = <<"e12ea248-94a5e885@192.168.5.3">>,
			mediaid = <<"1">>,
			from = #party{tag = <<"6b0a8f6cfc543db1o1">>, addr = {{192,0,43,5}, 16432}, rtcpaddr = {{192,0,43,5}, 16433}},
			params = [
				{codecs, [
						{'PCMA',8000,1},
						{'PCMU',8000,1},
						2,
						{'G723',8000,1},
						{'G729',8000,1},
						96,
						97,
						98,
						100,
						101
					]
				},
				{direction, {external, external}},
				{symmetric, true},
				{transcode, {'G723',8000,1}}
			]
		}, ser_proto:decode(<<"438_41061 Ut4c8,0,2,4,18,96,97,98,100,101 e12ea248-94a5e885@192.168.5.3 192.0.43.5 16432 6b0a8f6cfc543db1o1;1">>)).

%parse_cmd_u_3_3_transcode_incompatible_test() ->
%	?assertThrow(
%		{error_syntax, "Requested transcoding to incompatible codec"},
%		ser_proto:decode(<<"438_41061 Ut5c8,0,2,4,18,96,97,98,100,101 e12ea248-94a5e885@192.168.5.3 192.168.5.3 16432 6b0a8f6cfc543db1o1;1">>)).
parse_cmd_u_3_3_transcode_incompatible_test() ->
	?assertEqual(
		#cmd{
			type = ?CMD_U,
			cookie = <<"438_41061">>,
			origin = #origin{type = ser, pid = self()},
			callid = <<"e12ea248-94a5e885@192.168.5.3">>,
			mediaid = <<"1">>,
			from = #party{tag = <<"6b0a8f6cfc543db1o1">>},
			params = [
				{codecs, [
						{'PCMA',8000,1},
						{'PCMU',8000,1},
						2,
						{'G723',8000,1},
						{'G729',8000,1},
						96,
						97,
						98,
						100,
						101
					]
				},
				{direction, {external, external}},
				{symmetric, true}
			]
		}, ser_proto:decode(<<"438_41061 Ut5c8,0,2,4,18,96,97,98,100,101 e12ea248-94a5e885@192.168.5.3 192.168.5.3 16432 6b0a8f6cfc543db1o1;1">>)).

%parse_cmd_u_3_4_transcode_no_codecs_test() ->
%	?assertThrow(
%		{error_syntax, "Requested transcoding but no codecs are available"},
%		ser_proto:decode(<<"438_41061 Ut1 e12ea248-94a5e885@192.168.5.3 192.168.5.3 16432 6b0a8f6cfc543db1o1;1">>)).
parse_cmd_u_3_4_transcode_no_codecs_test() ->
	?assertEqual(
		#cmd{
			type = ?CMD_U,
			cookie = <<"438_41061">>,
			origin = #origin{type = ser, pid = self()},
			callid = <<"e12ea248-94a5e885@192.168.5.3">>,
			mediaid = <<"1">>,
			from = #party{tag = <<"6b0a8f6cfc543db1o1">>},
			params = [
				{direction, {external, external}},
				{symmetric, true}
			]
		}, ser_proto:decode(<<"438_41061 Ut1 e12ea248-94a5e885@192.168.5.3 192.168.5.3 16432 6b0a8f6cfc543db1o1;1">>)).

parse_cmd_u_4_zeroes_test() ->
	?assertEqual(
		#cmd{
			type = ?CMD_U,
			cookie = <<"5958_7">>,
			origin = #origin{type = ser, pid = self()},
			callid = <<"ffe0100519df4bc1bbd2f8e18309ca8a">>,
			mediaid = <<"2">>,
			from = #party{tag = <<"186f101b0e04481ea045517edb93b62d">>, addr = {{192,0,43,7}, 19268}, rtcpaddr = {{192,0,43,7}, 19269}},
			params = [
				{codecs, [
						{'H263',90000,0},
						{'H261',90000,0}
					]
				},
				{direction, {external, external}},
				{repacketize, 30},
				{symmetric, true}
			]
		}, ser_proto:decode(<<<<"5958_7 UZ30">>/binary, 0, 0, 0, <<"c34,31 ffe0100519df4bc1bbd2f8e18309ca8a 192.0.43.7 19268 186f101b0e04481ea045517edb93b62d;2">>/binary>>)).

parse_cmd_u_5_proto_test() ->
	?assertEqual(
		#cmd{
			type = ?CMD_U,
			cookie = <<"438_41061">>,
			origin = #origin{type = ser, pid = self()},
			callid = <<"e12ea248-94a5e885@192.168.5.3">>,
			mediaid = <<"1">>,
			from = #party{tag = <<"6b0a8f6cfc543db1o1">>, addr = {{192,0,43,4}, 16432}, rtcpaddr = {{192,0,43,4}, 16433}, proto = tcp},
			params = [
				{codecs, [
						{'PCMA',8000,1},
						{'PCMU',8000,1},
						2,
						{'G723',8000,1},
						{'G729',8000,1},
						96,
						97,
						98,
						100,
						101
					]
				},
				{direction, {external, external}},
				{symmetric, true},
				{transcode, {'G723',8000,1}}
			]
		}, ser_proto:decode(<<"438_41061 Ut4p1c8,0,2,4,18,96,97,98,100,101 e12ea248-94a5e885@192.168.5.3 192.0.43.4 16432 6b0a8f6cfc543db1o1;1">>)).

parse_cmd_u_6_0_internal_to_internal_test() ->
	?assertEqual(
		#cmd{
			type = ?CMD_U,
			cookie = <<"438_41061">>,
			origin = #origin{type = ser, pid = self()},
			callid = <<"e12ea248-94a5e885@192.168.5.3">>,
			mediaid = <<"1">>,
			from = #party{tag = <<"6b0a8f6cfc543db1o1">>, addr = {{192,168,5,3}, 16432}, rtcpaddr = {{192,168,5,3}, 16433}, proto = tcp},
			params = [
				{codecs, [
						{'PCMA',8000,1},
						{'PCMU',8000,1},
						2,
						{'G723',8000,1},
						{'G729',8000,1},
						96,
						97,
						98,
						100,
						101
					]
				},
				{direction, {internal, internal}},
				{symmetric, true},
				{transcode, {'G723',8000,1}}
			]
		}, ser_proto:decode(<<"438_41061 Ut4p1iic8,0,2,4,18,96,97,98,100,101 e12ea248-94a5e885@192.168.5.3 192.168.5.3 16432 6b0a8f6cfc543db1o1;1">>)).

parse_cmd_u_6_1_internal_to_external_test() ->
	?assertEqual(
		#cmd{
			type = ?CMD_U,
			cookie = <<"438_41061">>,
			origin = #origin{type = ser, pid = self()},
			callid = <<"e12ea248-94a5e885@192.168.5.3">>,
			mediaid = <<"1">>,
			from = #party{tag = <<"6b0a8f6cfc543db1o1">>, addr = {{192,168,5,3}, 16432}, rtcpaddr = {{192,168,5,3}, 16433}, proto = tcp},
			params = [
				{codecs, [
						{'PCMA',8000,1},
						{'PCMU',8000,1},
						2,
						{'G723',8000,1},
						{'G729',8000,1},
						96,
						97,
						98,
						100,
						101
					]
				},
				{direction, {internal, external}},
				{symmetric, true},
				{transcode, {'G723',8000,1}}
			]
		}, ser_proto:decode(<<"438_41061 Ut4p1iec8,0,2,4,18,96,97,98,100,101 e12ea248-94a5e885@192.168.5.3 192.168.5.3 16432 6b0a8f6cfc543db1o1;1">>)).

parse_cmd_u_6_2_external_to_internal_test() ->
	?assertEqual(
		#cmd{
			type = ?CMD_U,
			cookie = <<"438_41061">>,
			origin = #origin{type = ser, pid = self()},
			callid = <<"e12ea248-94a5e885@192.168.5.3">>,
			mediaid = <<"1">>,
			from = #party{tag = <<"6b0a8f6cfc543db1o1">>, addr = {{192,0,43,3}, 16432}, rtcpaddr = {{192,0,43,3}, 16433}, proto = tcp},
			params = [
				{codecs, [
						{'PCMA',8000,1},
						{'PCMU',8000,1},
						2,
						{'G723',8000,1},
						{'G729',8000,1},
						96,
						97,
						98,
						100,
						101
					]
				},
				{direction, {external, internal}},
				{symmetric, true},
				{transcode, {'G723',8000,1}}
			]
		}, ser_proto:decode(<<"438_41061 Ut4p1eic8,0,2,4,18,96,97,98,100,101 e12ea248-94a5e885@192.168.5.3 192.0.43.3 16432 6b0a8f6cfc543db1o1;1">>)).

parse_cmd_u_6_3_external_to_external_test() ->
	?assertEqual(
		#cmd{
			type = ?CMD_U,
			cookie = <<"438_41061">>,
			origin = #origin{type = ser, pid = self()},
			callid = <<"e12ea248-94a5e885@192.168.5.3">>,
			mediaid = <<"1">>,
			from = #party{tag = <<"6b0a8f6cfc543db1o1">>, addr = {{192,0,43,3}, 16432}, rtcpaddr = {{192,0,43,3}, 16433}, proto = tcp},
			params = [
				{codecs, [
						{'PCMA',8000,1},
						{'PCMU',8000,1},
						2,
						{'G723',8000,1},
						{'G729',8000,1},
						96,
						97,
						98,
						100,
						101
					]
				},
				{direction, {external, external}},
				{symmetric, true},
				{transcode, {'G723',8000,1}}
			]
		}, ser_proto:decode(<<"438_41061 Ut4p1eec8,0,2,4,18,96,97,98,100,101 e12ea248-94a5e885@192.168.5.3 192.0.43.3 16432 6b0a8f6cfc543db1o1;1">>)).

parse_cmd_u_6_4_internal_to_internal_single_test() ->
	?assertEqual(
		#cmd{
			type = ?CMD_U,
			cookie = <<"438_41061">>,
			origin = #origin{type = ser, pid = self()},
			callid = <<"e12ea248-94a5e885@192.168.5.3">>,
			mediaid = <<"1">>,
			from = #party{tag = <<"6b0a8f6cfc543db1o1">>, addr = {{192,168,5,3}, 16432}, rtcpaddr = {{192,168,5,3}, 16433}, proto = tcp},
			params = [
				{codecs, [
						{'PCMA',8000,1},
						{'PCMU',8000,1},
						2,
						{'G723',8000,1},
						{'G729',8000,1},
						96,
						97,
						98,
						100,
						101
					]
				},
				{direction, {internal, internal}},
				{symmetric, true},
				{transcode, {'G723',8000,1}}
			]
		}, ser_proto:decode(<<"438_41061 Ut4p1ic8,0,2,4,18,96,97,98,100,101 e12ea248-94a5e885@192.168.5.3 192.168.5.3 16432 6b0a8f6cfc543db1o1;1">>)).

parse_cmd_u_6_5_external_to_external_single_test() ->
	?assertEqual(
		#cmd{
			type = ?CMD_U,
			cookie = <<"438_41061">>,
			origin = #origin{type = ser, pid = self()},
			callid = <<"e12ea248-94a5e885@192.168.5.3">>,
			mediaid = <<"1">>,
			from = #party{tag = <<"6b0a8f6cfc543db1o1">>, addr = {{192,0,43,3}, 16432}, rtcpaddr = {{192,0,43,3}, 16433}, proto = tcp},
			params = [
				{codecs, [
						{'PCMA',8000,1},
						{'PCMU',8000,1},
						2,
						{'G723',8000,1},
						{'G729',8000,1},
						96,
						97,
						98,
						100,
						101
					]
				},
				{direction, {external, external}},
				{symmetric, true},
				{transcode, {'G723',8000,1}}
			]
		}, ser_proto:decode(<<"438_41061 Ut4p1ec8,0,2,4,18,96,97,98,100,101 e12ea248-94a5e885@192.168.5.3 192.0.43.3 16432 6b0a8f6cfc543db1o1;1">>)).

parse_cmd_u_7_both_symmetric_and_asymmetric_test() ->
	?assertThrow(
		{error_syntax, "Both symmetric and asymmetric modifiers are defined"},
		ser_proto:decode(<<"438_41061 Ut4p1asc8,0,2,4,18,96,97,98,100,101 e12ea248-94a5e885@192.168.5.3 192.168.5.3 16432 6b0a8f6cfc543db1o1;1">>)).

parse_cmd_u_8_acc_start_test() ->
	?assertEqual(
		#cmd{
			type = ?CMD_U,
			cookie = <<"438_41061">>,
			origin = #origin{type = ser, pid = self()},
			callid = <<"e12ea248-94a5e885@192.168.5.3">>,
			mediaid = <<"1">>,
			from = #party{tag = <<"6b0a8f6cfc543db1o1">>, addr = {{192, 0, 43, 3}, 16432}, rtcpaddr = {{192, 0, 43, 3}, 16433}, proto = tcp},
			params = [
				{acc, start},
				{codecs, [
						{'PCMA',8000,1},
						{'PCMU',8000,1},
						2,
						{'G723',8000,1},
						{'G729',8000,1},
						96,
						97,
						98,
						100,
						101
					]
				},
				{direction, {external, external}},
				{symmetric, true},
				{transcode, {'G723',8000,1}}
			]
		}, ser_proto:decode(<<"438_41061 Ut4p1c8,0,2,4,18,96,97,98,100,101v0 e12ea248-94a5e885@192.168.5.3 192.0.43.3 16432 6b0a8f6cfc543db1o1;1">>)).

parse_cmd_u_9_acc_interim_update_test() ->
	?assertEqual(
		#cmd{
			type = ?CMD_U,
			cookie = <<"438_41061">>,
			origin = #origin{type = ser, pid = self()},
			callid = <<"e12ea248-94a5e885@192.168.5.3">>,
			mediaid = <<"1">>,
			from = #party{tag = <<"6b0a8f6cfc543db1o1">>, addr = {{192, 0, 43, 3}, 16432}, rtcpaddr = {{192, 0, 43, 3}, 16433}, proto = tcp},
			params = [
				{acc, interim_update},
				{codecs, [
						{'PCMA',8000,1},
						{'PCMU',8000,1},
						2,
						{'G723',8000,1},
						{'G729',8000,1},
						96,
						97,
						98,
						100,
						101
					]
				},
				{direction, {external, external}},
				{symmetric, true},
				{transcode, {'G723',8000,1}}
			]
		}, ser_proto:decode(<<"438_41061 Ut4p1c8,0,2,4,18,96,97,98,100,101v0v1 e12ea248-94a5e885@192.168.5.3 192.0.43.3 16432 6b0a8f6cfc543db1o1;1">>)).

parse_cmd_u_10_acc_stop_test() ->
	?assertEqual(
		#cmd{
			type = ?CMD_U,
			cookie = <<"438_41061">>,
			origin = #origin{type = ser, pid = self()},
			callid = <<"e12ea248-94a5e885@192.168.5.3">>,
			mediaid = <<"1">>,
			from = #party{tag = <<"6b0a8f6cfc543db1o1">>, addr = {{192, 0, 43, 3}, 16432}, rtcpaddr = {{192, 0, 43, 3}, 16433}, proto = tcp},
			params = [
				{acc, stop},
				{codecs, [
						{'PCMA',8000,1},
						{'PCMU',8000,1},
						2,
						{'G723',8000,1},
						{'G729',8000,1},
						96,
						97,
						98,
						100,
						101
					]
				},
				{direction, {external, external}},
				{symmetric, true},
				{transcode, {'G723',8000,1}}
			]
		}, ser_proto:decode(<<"438_41061 Ut4p1c8,0,2,4,18,96,97,98,100,101v0v1v2 e12ea248-94a5e885@192.168.5.3 192.0.43.3 16432 6b0a8f6cfc543db1o1;1">>)).

parse_cmd_u_11_wrong_ipv4_test() ->
	?assertThrow(
		{error_syntax, {"Wrong IP","892.168.0.100"}},
		ser_proto:decode(<<"24393_4 Uc0,8,18,101 0003e30c-c50c00f7-123e8bd9-542f2edf@192.168.0.100 892.168.0.100 27686 0003e30cc50cd69210b8c36b-0ecf0120;1">>)).

parse_cmd_u_12_wrong_port_test() ->
	?assertThrow(
		{error_syntax, {"Wrong port", "627686"}},
		ser_proto:decode(<<"24393_4 Uc0,8,18,101 0003e30c-c50c00f7-123e8bd9-542f2edf@192.168.0.100 192.168.0.100 627686 0003e30cc50cd69210b8c36b-0ecf0120;1">>)).

% MediaID is just an arbitrary tag within session so it depends on backend how to process it
%parse_cmd_u_13_wrong_mediaid_test() ->
%	?assertThrow(
%		{error_syntax, "Wrong MediaID"},
%		ser_proto:decode(<<"24393_4 Uc0,8,18,101 0003e30c-c50c00f7-123e8bd9-542f2edf@192.168.0.100 192.168.0.100 27686 0003e30cc50cd69210b8c36b-0ecf0120;foo">>)).

parse_cmd_u_14_discard_rfc1918_test() ->
	?assertEqual(
		#cmd{
			type = ?CMD_U,
			cookie = <<"438_41061">>,
			origin = #origin{type = ser, pid = self()},
			callid = <<"e12ea248-94a5e885@192.168.5.3">>,
			mediaid = <<"1">>,
			from = #party{tag = <<"6b0a8f6cfc543db1o1">>, proto = tcp},
			params = [
				{acc, stop},
				{codecs, [
						{'PCMA',8000,1},
						{'PCMU',8000,1},
						2,
						{'G723',8000,1},
						{'G729',8000,1},
						96,
						97,
						98,
						100,
						101
					]
				},
				{direction, {external, external}},
				{symmetric, true},
				{transcode, {'G723',8000,1}}
			]
		}, ser_proto:decode(<<"438_41061 Ut4p1c8,0,2,4,18,96,97,98,100,101v0v1v2 e12ea248-94a5e885@192.168.5.3 192.168.43.3 16432 6b0a8f6cfc543db1o1;1">>)).

parse_cmd_u_15_discard_non_rfc1918_test() ->
	?assertEqual(
		#cmd{
			type = ?CMD_U,
			cookie = <<"438_41061">>,
			origin = #origin{type = ser, pid = self()},
			callid = <<"e12ea248-94a5e885@192.168.5.3">>,
			mediaid = <<"1">>,
			from = #party{tag = <<"6b0a8f6cfc543db1o1">>, proto = tcp},
			params = [
				{acc, stop},
				{codecs, [
						{'PCMA',8000,1},
						{'PCMU',8000,1},
						2,
						{'G723',8000,1},
						{'G729',8000,1},
						96,
						97,
						98,
						100,
						101
					]
				},
				{direction, {internal, external}},
				{symmetric, true},
				{transcode, {'G723',8000,1}}
			]
		}, ser_proto:decode(<<"438_41061 Ut4p1iec8,0,2,4,18,96,97,98,100,101v0v1v2 e12ea248-94a5e885@192.168.5.3 192.0.43.3 16432 6b0a8f6cfc543db1o1;1">>)).

parse_cmd_u_16_ipv6_source_test() ->
	?assertEqual(
		#cmd{
			type = ?CMD_U,
			cookie = <<"9440_4">>,
			origin = #origin{type = ser, pid = self()},
			callid = <<"e12050ca82cc434c444ae66fcb30a4c0@0:0:0:0:0:0:0:0">>,
			mediaid = <<"1">>,
			from = #party{tag = <<"595f563">>, addr = {{8193, 1280, 136, 512, 0, 0, 0, 16}, 5000}, rtcpaddr = {{8193, 1280, 136, 512, 0, 0, 0, 16}, 5001}, proto = udp},
			params = [
				ipv6,
				weak,
				{codecs, [
						{'G722',8000,1},
						96,
						97,
						{'PCMU',8000,1},
						{'PCMA',8000,1},
						98,
						{'GSM',8000,1},
						100,
						{'DVI4',8000,1},
						{'DVI4',16000,1},
						{'G728',8000,1},
						101
					]
				},
				{direction, {external, external}},
				{repacketize, 30},
				{symmetric, true},
				{transcode, {'GSM',8000,1}}
			]
		}, ser_proto:decode(<<"9440_4 UwEEt3Z30c9,96,97,0,8,98,3,100,5,6,15,101 e12050ca82cc434c444ae66fcb30a4c0@0:0:0:0:0:0:0:0 2001:500:88:200:0:0:0:10 5000 595f563;1">>)).

parse_cmd_u_17_notify_port_test() ->
	?assertEqual(
		#cmd{
			type = ?CMD_U,
			cookie = <<"438_41061">>,
			origin = #origin{type = ser, pid = self()},
			callid = <<"e12ea248-94a5e885@192.168.5.3">>,
			mediaid = <<"1">>,
			from = #party{tag = <<"6b0a8f6cfc543db1o1">>, addr = {{192,0,43,4}, 16432}, rtcpaddr = {{192,0,43,4}, 16433}, proto = tcp},
			to = #party{tag = <<"595f563">>},
			params = [
				{codecs, [
						{'PCMA',8000,1},
						{'PCMU',8000,1},
						2,
						{'G723',8000,1},
						{'G729',8000,1},
						96,
						97,
						98,
						100,
						101
					]
				},
				{direction, {external, external}},
				{notify, [{addr, 4123}, {tag, <<"27124048">>}]},
				{symmetric, true},
				{transcode, {'G723',8000,1}}
			]
		}, ser_proto:decode(<<"438_41061 Ut4p1c8,0,2,4,18,96,97,98,100,101 e12ea248-94a5e885@192.168.5.3 192.0.43.4 16432 6b0a8f6cfc543db1o1;1 595f563;1 4123 27124048">>)).

parse_cmd_u_18_notify_ipv4_and_port_test() ->
	?assertEqual(
		#cmd{
			type = ?CMD_U,
			cookie = <<"438_41061">>,
			origin = #origin{type = ser, pid = self()},
			callid = <<"e12ea248-94a5e885@192.168.5.3">>,
			mediaid = <<"1">>,
			from = #party{tag = <<"6b0a8f6cfc543db1o1">>, addr = {{192,0,43,4}, 16432}, rtcpaddr = {{192,0,43,4}, 16433}, proto = tcp},
			to = #party{tag = <<"595f563">>},
			params = [
				{codecs, [
						{'PCMA',8000,1},
						{'PCMU',8000,1},
						2,
						{'G723',8000,1},
						{'G729',8000,1},
						96,
						97,
						98,
						100,
						101
					]
				},
				{direction, {external, external}},
				{notify, [{addr, {{192,168,0,1},4123}}, {tag, <<"27124048">>}]},
				{symmetric, true},
				{transcode, {'G723',8000,1}}
			]
		}, ser_proto:decode(<<"438_41061 Ut4p1c8,0,2,4,18,96,97,98,100,101 e12ea248-94a5e885@192.168.5.3 192.0.43.4 16432 6b0a8f6cfc543db1o1;1 595f563;1 192.168.0.1:4123 27124048">>)).

%parse_cmd_u_19_notify_ipv6_and_port_test() ->
%	?assertEqual(
%		#cmd{
%			type = ?CMD_U,
%			cookie = <<"438_41061">>,
%			origin = #origin{type = ser, pid = self()},
%			callid = <<"e12ea248-94a5e885@192.168.5.3">>,
%			mediaid = <<"1">>,
%			from = #party{tag = <<"6b0a8f6cfc543db1o1">>, addr = {{192,0,43,4}, 16432}, rtcpaddr = {{192,0,43,4}, 16433}, proto = tcp},
%			to = #party{tag = <<"595f563">>},
%			params = [
%				{codecs, [
%						{'PCMA',8000,1},
%						{'PCMU',8000,1},
%						2,
%						{'G723',8000,1},
%						{'G729',8000,1},
%						96,
%						97,
%						98,
%						100,
%						101
%					]
%				},
%				{direction, {external, external}},
%				{notify, [{addr, {{8193,1280,136,512,0,0,0,16},4123}}, {tag, <<"27124048">>}]},
%				{symmetric, true},
%				{transcode, {'G723',8000,1}}
%			]
%		}, ser_proto:decode(<<"438_41061 Ut4p1c8,0,2,4,18,96,97,98,100,101 e12ea248-94a5e885@192.168.5.3 192.0.43.4 16432 6b0a8f6cfc543db1o1;1 595f563;1 2001:500:88:200:0:0:0:10:4123 27124048">>)).

parse_cmd_u_20_no_mediaids_test() ->
	?assertEqual(
		#cmd{
			type = ?CMD_U,
			cookie = <<"c3c1de658b0d36443a646cefedf16434">>,
			origin = #origin{type = ser, pid = self()},
			callid = <<"smaalefzrxxfrqw@localhost.localdomain-0">>,
			mediaid = <<"0">>,
			from = #party{tag = <<"qooxb">>},
			to = #party{tag = <<"aa436b4e2d3bb3185841946c849a7ca7">>},
			params = [
				{direction, {external, external}},
				{notify, [{addr, 4123}, {tag, <<"28221712">>}]},
				{symmetric, true}
			]
		}, ser_proto:decode(<<"c3c1de658b0d36443a646cefedf16434 U smaalefzrxxfrqw@localhost.localdomain-0 192.168.0.1 8000 qooxb aa436b4e2d3bb3185841946c849a7ca7 4123 28221712">>)).

parse_cmd_u_21_wrong_ipv6_test() ->
	?assertThrow(
		{error_syntax,{"Wrong IP","fe80::ff:ff:ff:ff%eth0"}},
		ser_proto:decode(<<"3898_5 USc0 2-1649@fe80::ff:ff:ff:ff%eth0 fe80::ff:ff:ff:ff%eth0 6000 1649SIPpTag002;1">>)).

cmd_l_test_() ->
	Cmd1 = #cmd{
			type = ?CMD_L,
			cookie = <<"413_40797">>,
			origin = #origin{type = ser, pid = self()},
			callid = <<"452ca314-3bbcf0ea@192.168.0.2">>,
			mediaid = <<"1">>,
			from = #party{tag = <<"8d11d16a3b56fcd588d72b3d359cc4e1">>, addr = {{192, 0, 43, 4}, 17050}, rtcpaddr = {{192, 0, 43, 4}, 17051}},
			to = #party{tag = <<"e4920d0cb29cf52o0">>},
			params = [
				{codecs, [
						{'PCMU',8000,1},
						101,
						100
					]
				},
				{direction, {external, external}},
				{symmetric, true}
			]
		},
	Cmd2 = #cmd{
			type = ?CMD_L,
			cookie = <<"418_41111">>,
			origin = #origin{type = ser, pid = self()},
			callid = <<"a68e961-5f6a75e5-356cafd9-3562@192.168.100.6">>,
			mediaid = <<"1">>,
			from = #party{tag = <<"60753eabbd87fe6f34068e9d80a9fc1c">>, addr = {{192, 168, 100, 4}, 18756}, rtcpaddr = {{192, 168, 100, 4}, 18757}},
			to = #party{tag = <<"1372466422">>},
			params = [
				{codecs, [
						{'PCMA',8000,1},
						101,
						100
					]
				},
				{direction, {internal, internal}},
				{symmetric, true}
			]
		},

	Cmd1Bin = <<"413_40797 Lc0,101,100 452ca314-3bbcf0ea@192.168.0.2 192.0.43.4 17050 e4920d0cb29cf52o0;1 8d11d16a3b56fcd588d72b3d359cc4e1;1\n">>,
	Cmd2Bin = <<"418_41111 LIc8,101,100 a68e961-5f6a75e5-356cafd9-3562@192.168.100.6 192.168.100.4 18756 1372466422;1 60753eabbd87fe6f34068e9d80a9fc1c;1\n">>,

	% Added default parameters
	% FIXME this really needs work
	Cmd1BinExtended = <<"413_40797 Lc0,101,100 452ca314-3bbcf0ea@192.168.0.2 192.0.43.4 17050 e4920d0cb29cf52o0;1 8d11d16a3b56fcd588d72b3d359cc4e1;1\n">>,
	Cmd2BinExtended = <<"418_41111 Liic8,101,100 a68e961-5f6a75e5-356cafd9-3562@192.168.100.6 192.168.100.4 18756 1372466422;1 60753eabbd87fe6f34068e9d80a9fc1c;1\n">>,
%	Cmd1BinExtended = <<"413_40797 Leesc0,101,100 452ca314-3bbcf0ea@192.168.0.2 192.0.43.4 17050 e4920d0cb29cf52o0;1 8d11d16a3b56fcd588d72b3d359cc4e1;1\n">>,
%	Cmd2BinExtended = <<"418_41111 Liisc8,101,100 a68e961-5f6a75e5-356cafd9-3562@192.168.100.6 192.168.100.4 18756 1372466422;1 60753eabbd87fe6f34068e9d80a9fc1c;1\n">>,

	[
		{"decoding from binary (Ext <-> Ext)",
			fun() -> ?assertEqual(Cmd1, ser_proto:decode(Cmd1Bin)) end
		},
		{"encoding to binary (Ext <-> Ext)",
			fun() -> ?assertEqual(Cmd1BinExtended, ser_proto:encode(Cmd1)) end
		},
		{"decoding from binary (Int <-> Int)",
			fun() -> ?assertEqual(Cmd2, ser_proto:decode(Cmd2Bin)) end
		},
		{"encoding to binary (Int <-> Int)",
			fun() -> ?assertEqual(Cmd2BinExtended, ser_proto:encode(Cmd2)) end
		}
	].

cmd_d_test_() ->
	Cmd1 = #cmd{
			type = ?CMD_D,
			cookie = <<"441_40922">>,
			origin = #origin{type = ser, pid = self()},
			callid = <<"2498331773@192.168.1.37">>,
			from = #party{tag = <<"8edccef4eb1a16b8cef7192b77b7951a">>}
		},
	Cmd2 = #cmd{
			type = ?CMD_D,
			cookie = <<"437_40882">>,
			origin = #origin{type = ser, pid = self()},
			callid = <<"7adc6214-268583a6-1b74a438-3548@192.168.100.6">>,
			from = #party{tag = <<"1372466422">>},
			to = #party{tag = <<"9c56ba15bd794082ce6b166dba6c9c2">>}
		},
	Cmd1Bin = <<"441_40922 D 2498331773@192.168.1.37 8edccef4eb1a16b8cef7192b77b7951a\n">>,
	Cmd2Bin = <<"437_40882 D 7adc6214-268583a6-1b74a438-3548@192.168.100.6 1372466422 9c56ba15bd794082ce6b166dba6c9c2\n">>,

	[
		{"decoding from binary (no ToTag)",
			fun() -> ?assertEqual(Cmd1, ser_proto:decode(Cmd1Bin)) end
		},
		{"encoding to binary (no ToTag)",
			fun() -> ?assertEqual(Cmd1Bin, ser_proto:encode(Cmd1)) end
		},
		{"decoding from binary",
			fun() -> ?assertEqual(Cmd2, ser_proto:decode(Cmd2Bin)) end
		},
		{"encoding to binary",
			fun() -> ?assertEqual(Cmd2Bin, ser_proto:encode(Cmd2)) end
		}
	].

cmd_r_test_() ->
	Cmd1 = #cmd{
			type = ?CMD_R,
			cookie = <<"393_6">>,
			origin = #origin{type = ser, pid = self()},
			callid = <<"0003e348-e21901f6-29cc58a1-379f3ffd@192.168.0.1">>,
			mediaid = <<"0">>,
			from = #party{tag = <<"0003e348e219767510f1e38f-47c56231">>},
			to = null,
			params = [
				{filename, default}
			]
		},
	Cmd2 = #cmd{
			type = ?CMD_R,
			cookie = <<"32711_5">>,
			origin = #origin{type = ser, pid = self()},
			callid = <<"0003e30c-c50c016a-35dc4387-58a65654@192.168.0.100">>,
			mediaid = <<"0">>,
			from = #party{tag = <<"eb1f1ca7e74cf0fc8a81ea331486452a">>},
			to = #party{tag = <<"0003e30cc50ccbed0342cc8d-0bddf550">>},
			params = [
				{filename, default}
			]
		},
	Cmd1Bin = <<"393_6 R 0003e348-e21901f6-29cc58a1-379f3ffd@192.168.0.1 0003e348e219767510f1e38f-47c56231\n">>,
	Cmd2Bin = <<"32711_5 R 0003e30c-c50c016a-35dc4387-58a65654@192.168.0.100 eb1f1ca7e74cf0fc8a81ea331486452a 0003e30cc50ccbed0342cc8d-0bddf550\n">>,

	[
		{"decoding from binary (no ToTag)",
			fun() -> ?assertEqual(Cmd1, ser_proto:decode(Cmd1Bin)) end
		},
		{"encoding to binary (no ToTag)",
			fun() -> ?assertEqual(Cmd1Bin, ser_proto:encode(Cmd1)) end
		},
		{"decoding from binary",
			fun() -> ?assertEqual(Cmd2, ser_proto:decode(Cmd2Bin)) end
		},
		{"encoding to binary",
			fun() -> ?assertEqual(Cmd2Bin, ser_proto:encode(Cmd2)) end
		}
	].

cmd_p_test_() ->
	Cmd1 = #cmd{
			type = ?CMD_P,
			cookie = <<"2154_5">>,
			origin = #origin{type = ser, pid = self()},
			callid = <<"0003e30c-c50c0171-35b90751-013a3ef6@192.168.0.100">>,
			mediaid = <<"1">>,
			from = #party{tag = <<"0003e30cc50ccc9f743d4fa6-38d0bd14">>},
			to = null,
			params = [
				{codecs, [
						{'PCMA',8000,1},
						{'PCMU',8000,1},
						101
					]
				},
				{filename, <<"/var/run/tmp/hello_uac.wav">>},
				{playcount, 20}
			]
		},
	Cmd2 = #cmd{
			type = ?CMD_P,
			cookie = <<"1389_5">>,
			origin = #origin{type = ser, pid = self()},
			callid = <<"0003e30c-c50c016d-46bbcf2e-6369eecf@192.168.0.100">>,
			mediaid = <<"1">>,
			from = #party{tag = <<"0003e30cc50ccc5416857d59-357336dc">>},
			to = #party{tag = <<"28d49e51a95d5a31d09b31ccc63c5f4b">>},
			params = [
				{codecs, [
						{'PCMA',8000,1},
						{'PCMU',8000,1},
						101
					]
				},
				{filename, <<"/var/tmp/rtpproxy_test/media/01.wav">>},
				{playcount, 10}
			]
		},
	Cmd1Bin = <<"2154_5 P20 0003e30c-c50c0171-35b90751-013a3ef6@192.168.0.100 /var/run/tmp/hello_uac.wav 8,0,101 0003e30cc50ccc9f743d4fa6-38d0bd14;1\n">>,
	Cmd2Bin = <<"1389_5 P10 0003e30c-c50c016d-46bbcf2e-6369eecf@192.168.0.100 /var/tmp/rtpproxy_test/media/01.wav 8,0,101 0003e30cc50ccc5416857d59-357336dc;1 28d49e51a95d5a31d09b31ccc63c5f4b;1\n">>,

	[
		{"decoding from binary (no ToTag)",
			fun() -> ?assertEqual(Cmd1, ser_proto:decode(Cmd1Bin)) end
		},
		{"encoding to binary (no ToTag)",
			fun() -> ?assertEqual(Cmd1Bin, ser_proto:encode(Cmd1)) end
		},
		{"decoding from binary",
			fun() -> ?assertEqual(Cmd2, ser_proto:decode(Cmd2Bin)) end
		},
		{"encoding to binary",
			fun() -> ?assertEqual(Cmd2Bin, ser_proto:encode(Cmd2)) end
		},
		{"Wrong PlayCount",
			fun() -> ?assertThrow(
						{error_syntax, {"Wrong PlayCount", <<"HELLO">>}},
						ser_proto:decode(<<"1389_5 Phello 0003e30c-c50c016d-46bbcf2e-6369eecf@192.168.0.100 /var/tmp/rtpproxy_test/media/01.wav session 0003e30cc50ccc5416857d59-357336dc;1 28d49e51a95d5a31d09b31ccc63c5f4b;1\n">>))
			end
		}
	].

cmd_p_b2bua_test_() ->
	Cmd = #cmd{
			type = ?CMD_P,
			cookie = <<"c48cefdbbb29404b03c0130dde7a4d85">>,
			origin = #origin{type = ser, pid = self()},
			callid = <<"00192f73-cc5f002e-59bf7a37-05909bd2@192.168.1.71-0">>,
			mediaid = <<"0">>,
			from = #party{tag = <<"00192f73cc5fa60b4651ff30-2e0eb999">>},
			to = #party{tag = <<"509108fe255-1c76bd0-8ed7b811">>},
			params = [
				{codecs, [
						{'PCMA',8000,1},
						{'PCMU',8000,1},
						{'G729',8000,1},
						101
					]
				},
				{filename, <<"default_en">>},
				{playcount, 0}
			]
		},
	CmdBin = <<"c48cefdbbb29404b03c0130dde7a4d85 P0 00192f73-cc5f002e-59bf7a37-05909bd2@192.168.1.71-0 default_en 8,0,18,101 00192f73cc5fa60b4651ff30-2e0eb999 509108fe255-1c76bd0-8ed7b811">>,

	[
		{"decoding from binary",
			fun() -> ?assertEqual(Cmd, ser_proto:decode(CmdBin)) end
		},
		{"encoding to binary",
			fun() -> ?assertEqual(ser_proto:encode(Cmd), <<CmdBin/binary, "\n">>) end
		}
	].

cmd_p_default_codecs_test_() ->
	Cmd = #cmd{
			type = ?CMD_P,
			cookie = <<"c48cefdbbb29404b03c0130dde7a4d85">>,
			origin = #origin{type = ser, pid = self()},
			callid = <<"00192f73-cc5f002e-59bf7a37-05909bd2@192.168.1.71-0">>,
			mediaid = <<"0">>,
			from = #party{tag = <<"00192f73cc5fa60b4651ff30-2e0eb999">>},
			to = #party{tag = <<"509108fe255-1c76bd0-8ed7b811">>},
			params = [
				{codecs, [session]},
				{filename, <<"default_en">>},
				{playcount, 0}
			]
		},
	CmdBin = <<"c48cefdbbb29404b03c0130dde7a4d85 P0 00192f73-cc5f002e-59bf7a37-05909bd2@192.168.1.71-0 default_en session 00192f73cc5fa60b4651ff30-2e0eb999 509108fe255-1c76bd0-8ed7b811">>,

	[
		{"decoding from binary",
			fun() -> ?assertEqual(Cmd, ser_proto:decode(CmdBin)) end
		},
		{"encoding to binary",
			fun() -> ?assertEqual(ser_proto:encode(Cmd), <<CmdBin/binary, "\n">>) end
		}
	].

cmd_s_test_() ->
	Cmd1 = #cmd{
			type = ?CMD_S,
			cookie = <<"2154_6">>,
			origin = #origin{type = ser, pid = self()},
			callid = <<"0003e30c-c50c0171-35b90751-013a3ef6@192.168.0.100">>,
			mediaid = <<"1">>,
			from = #party{tag = <<"0003e30cc50ccc9f743d4fa6-38d0bd14">>}
		},
	Cmd2 = #cmd{
			type = ?CMD_S,
			cookie = <<"2154_6">>,
			origin = #origin{type = ser, pid = self()},
			callid = <<"0003e30c-c50c0171-35b90751-013a3ef6@192.168.0.100">>,
			mediaid = <<"1">>,
			from = #party{tag = <<"0003e30cc50ccc9f743d4fa6-38d0bd14">>},
			to = #party{tag = <<"9c56ba15bd794082ce6b166dba6c9c2">>}
		},
	Cmd1Bin = <<"2154_6 S 0003e30c-c50c0171-35b90751-013a3ef6@192.168.0.100 0003e30cc50ccc9f743d4fa6-38d0bd14;1\n">>,
	Cmd2Bin = <<"2154_6 S 0003e30c-c50c0171-35b90751-013a3ef6@192.168.0.100 0003e30cc50ccc9f743d4fa6-38d0bd14;1 9c56ba15bd794082ce6b166dba6c9c2;1\n">>,

	[
		{"decoding from binary (no ToTag)",
			fun() -> ?assertEqual(Cmd1, ser_proto:decode(Cmd1Bin)) end
		},
		{"encoding to binary (no ToTag)",
			fun() -> ?assertEqual(Cmd1Bin, ser_proto:encode(Cmd1)) end
		},
		{"decoding from binary",
			fun() -> ?assertEqual(Cmd2, ser_proto:decode(Cmd2Bin)) end
		},
		{"encoding to binary",
			fun() -> ?assertEqual(Cmd2Bin, ser_proto:encode(Cmd2)) end
		}
	].

cmd_q_test_() ->
	Cmd = #cmd{
			type = ?CMD_Q,
			cookie = <<"2154_6">>,
			origin = #origin{type = ser, pid = self()},
			callid = <<"0003e30c-c50c0171-35b90751-013a3ef6@192.168.0.100">>,
			mediaid = <<"1">>,
			from = #party{tag = <<"0003e30cc50ccc9f743d4fa6-38d0bd14">>},
			to = #party{tag = <<"9c56ba15bd794082ce6b166dba6c9c2">>}
		},
	CmdBin = <<"2154_6 Q 0003e30c-c50c0171-35b90751-013a3ef6@192.168.0.100 0003e30cc50ccc9f743d4fa6-38d0bd14;1 9c56ba15bd794082ce6b166dba6c9c2;1\n">>,

	[
		{"decoding from binary",
			fun() -> ?assertEqual(Cmd, ser_proto:decode(CmdBin)) end
		},
		{"encoding to binary",
			fun() -> ?assertEqual(CmdBin, ser_proto:encode(Cmd)) end
		}
	].
cmd_i_1_test_() ->
	Cmd = #cmd{
			type = ?CMD_I,
			cookie = <<"24390_0">>,
			origin = #origin{type = ser, pid = self()},
			params = []
		},
	CmdBin = <<"24390_0 I\n">>,
	[
		{"decoding from binary",
			fun() -> ?assertEqual(Cmd, ser_proto:decode(CmdBin)) end
		},
		{"encoding to binary",
			fun() -> ?assertEqual(CmdBin, ser_proto:encode(Cmd)) end
		}
	].

cmd_i_2_brief_test_() ->
	Cmd = #cmd{
			type = ?CMD_I,
			cookie = <<"24390_0">>,
			origin = #origin{type = ser, pid = self()},
			params = [brief]
		},
	CmdBin = <<"24390_0 IB\n">>,
	[
		{"decoding from binary",
			fun() -> ?assertEqual(Cmd, ser_proto:decode(CmdBin)) end
		},
		{"encoding to binary",
			fun() -> ?assertEqual(CmdBin, ser_proto:encode(Cmd)) end
		}
	].

cmd_x_test_() ->
	Cmd = #cmd{
			type = ?CMD_X,
			cookie = <<"24390_0">>,
			origin = #origin{type = ser, pid = self()}
		},
	CmdBin = <<"24390_0 X\n">>,
	[
		{"decoding from binary",
			fun() -> ?assertEqual(Cmd, ser_proto:decode(CmdBin)) end
		},
		{"encoding to binary",
			fun() -> ?assertEqual(CmdBin, ser_proto:encode(Cmd)) end
		}
	].

parse_cmd_unknown_test() ->
	?assertThrow(
		{error_syntax, "Unknown command"},
		ser_proto:decode(<<"2154_6 Z 0003e30c-c50c0171-35b90751-013a3ef6@192.168.0.100 0003e30cc50ccc9f743d4fa6-38d0bd14;1">>)).

parse_reply_ipv4_test() ->
	?assertEqual(
		#response{cookie = <<"8411_41413">>, type = reply, data = {{{192, 168, 100, 4}, 41212}, {{192, 168, 100, 4}, 41213}}},
		ser_proto:decode(<<"8411_41413 41212 192.168.100.4">>)).

parse_reply_ipv6_test() ->
	?assertEqual(
		#response{cookie = <<"8411_41413">>, type = reply, data = {{{8193, 1280, 136, 512, 0, 0, 0, 16}, 41212}, {{8193, 1280, 136, 512, 0, 0, 0, 16}, 41213}}},
		ser_proto:decode(<<"8411_41413 41212 2001:500:88:200::10">>)).

encode_ok_test() ->
	?assertEqual(<<"438_41067 0\n">>, ser_proto:encode(#response{cookie = <<"438_41067">>, type = reply, data = ok})).

encode_stats_brief_test() ->
	?assertEqual(<<"485cb8cd73c54462beace3d9ce7d52df5bac23ff active sessions: 42\n">>, ser_proto:encode(#response{cookie = <<"485cb8cd73c54462beace3d9ce7d52df5bac23ff">>, type = reply, data = {ok, {stats, 42}}})).

encode_ipv4_test() ->
	?assertEqual(
		<<"8411_41413 41212 192.168.100.4\n">>,
		ser_proto:encode(#response{cookie = <<"8411_41413">>, type = reply, data = {{{192, 168, 100, 4}, 41212}, {{192, 168, 100, 4}, 41213}}})).

encode_ipv6_test() ->
	?assertEqual(
		<<"8411_41413 41212 2001:500:88:200::10\n">>,
		ser_proto:encode(#response{cookie = <<"8411_41413">>, type = reply, data = {{{8193, 1280, 136, 512, 0, 0, 0, 16}, 41212}, {{8193, 1280, 136, 512, 0, 0, 0, 16}, 41213}}})).

encode_version_basic_test() ->
	?assertEqual(<<"32031_1 20040107\n">>, ser_proto:encode(#response{cookie = <<"32031_1">>, type = reply, data = {version, <<"20040107">>}})).

encode_version_supported_test() ->
	?assertEqual(<<"32031_3 1\n">>, ser_proto:encode(#response{cookie = <<"32031_3">>, type = reply, data = supported})).

encode_error_syntax_test() ->
	?assertEqual(<<"32098_3 E1\n">>, ser_proto:encode({error, syntax, <<"32098_3 hello there - some invalid command string">>})).

encode_error_software_test() ->
	?assertEqual(<<"24393_4 E7\n">>, ser_proto:encode(#response{cookie = <<"24393_4">>, type = error, data = software})).

encode_error_notfound_test() ->
	?assertEqual(<<"24393_4 E8\n">>, ser_proto:encode(#response{cookie = <<"24393_4">>, type = error, data = notfound})).
