void DisplayVoteDifficultyMenu(int client, int count, char items[5][64])
{
	LogAction(client, -1, "\"%L\" initiated a bot difficulty vote.", client);
	CPrintToChatAll("{valve}Incremental Fortress {white}| Initiated a vote for bot difficulty.");
	
	if (g_NativeVotes)
	{
		Handle hVoteMenu;
		if (count == 1)
		{
			strcopy(g_VoteInfo[VOTE_NAME], sizeof(g_VoteInfo[]), items[0]);

			hVoteMenu = NativeVotes_Create(Handler_NativeVoteCallback, NativeVotesType_Custom_YesNo, view_as<MenuAction>(MENU_ACTIONS_ALL));
			NativeVotes_SetTitle(hVoteMenu, "Change Difficulty To");
			// No details for custom votes
		}
		else
		{
			hVoteMenu = NativeVotes_Create(Handler_NativeVoteCallback, NativeVotesType_Custom_Mult, view_as<MenuAction>(MENU_ACTIONS_ALL));
			NativeVotes_SetTitle(hVoteMenu, "Difficulty Vote");
			for (int i = 0; i < count; i++)
			{
				NativeVotes_AddItem(hVoteMenu, items[i], items[i]);
			}	
		}
		NativeVotes_DisplayToAll(hVoteMenu, 20);
	}
}

public Action Command_VoteDifficulty(int client, int args)
{
	if (isMvM)
	{
		CReplyToCommand(client, "{valve}Incremental Fortress {white}| You cannot vote for bot difficulty in MvM.");
		return Plugin_Handled;
	}

	if (NativeVotes_IsVoteInProgress())
	{
		CReplyToCommand(client, "{valve}Incremental Fortress {white}| A vote is already in progress.");
		return Plugin_Handled;
	}
	
	int remainingTime = NativeVotes_CheckVoteDelay();

	if (remainingTime)
	{
		CReplyToCommand(client, "There is currently a %i second wait until the next vote.", remainingTime);
		return Plugin_Handled;
	}
	
	char items[5][64] ={"1.0","1.2","1.4","1.6","1.8"};
	DisplayVoteDifficultyMenu(client, 5, items);
	
	return Plugin_Handled;
}


public int Handler_NativeVoteCallback(Handle menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_End:
		{
			NativeVotes_Close(menu);
		}
		
		case MenuAction_Display:
		{
			NativeVotesType nVoteType = NativeVotes_GetType(menu);
			if (nVoteType == NativeVotesType_Custom_YesNo || nVoteType == NativeVotesType_Custom_Mult)
			{
				char title[64];
				NativeVotes_GetTitle(menu, title, sizeof(title));
				
				char buffer[255];
				Format(buffer, sizeof(buffer), "%T", title, param1, g_VoteInfo[VOTE_NAME]);
				
				return NativeVotes_RedrawVoteTitle(buffer);
			}
		}
		
		case MenuAction_VoteCancel:
		{
			if (param1 == VoteCancel_NoVotes)
			{
				NativeVotes_DisplayFail(menu, NativeVotesFail_NotEnoughVotes);
				CPrintToChatAll("No Votes Casted!");
			}
			else
			{
				NativeVotes_DisplayFail(menu, NativeVotesFail_Generic);
			}
		}
		
		case MenuAction_VoteEnd:
		{
			char item[64];
			float percent, limit;
			int votes, totalVotes;
			
			NativeVotesType nVoteType = NativeVotes_GetType(menu);

			NativeVotes_GetInfo(param2, votes, totalVotes);
			NativeVotes_GetItem(menu, param1, item, sizeof(item));
			
			if (nVoteType == NativeVotesType_Custom_YesNo && param1 == NATIVEVOTES_VOTE_NO)
			{
				votes = totalVotes - votes; // Reverse the votes to be in relation to the Yes option.
			}
			
			percent = float(votes) / float(totalVotes);
			
			limit = 0.6;

			if ((nVoteType != NativeVotesType_NextLevelMult && nVoteType != NativeVotesType_Custom_Mult) && ((param1 == NATIVEVOTES_VOTE_YES && FloatCompare(percent,limit) < 0) || (param1 == NATIVEVOTES_VOTE_NO)))
			{
				NativeVotes_DisplayFail(menu, NativeVotesFail_Loses);
				LogAction(-1, -1, "Vote failed.");
				CPrintToChatAll("{valve}Incremental Fortress {white}| Vote Failed, %i%% quota is required. Only received %i%% of %i total votes.", RoundToNearest(100.0*limit), RoundToNearest(100.0*percent), totalVotes);
			}
			else
			{
				CPrintToChatAll("{valve}Incremental Fortress {white}| Vote Successful, %i%% out of %i total votes.", RoundToNearest(100.0*percent), totalVotes);
				
				switch (g_VoteType)
				{
					case difficulty:
					{
						NativeVotes_DisplayPassCustom(menu, "Changed difficulty to %sx!", item);
						LogAction(-1, -1, "Changing difficulty to %sx due to vote.", item);
						SetConVarFloat(cvar_BotMultiplier, StringToFloat(item));
					}			
				}
			}
		}
	}
	
	return Plugin_Continue;
}