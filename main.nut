/*
 * This file is part of CityConnecter.
 *
 * CityConnecter is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 2 of the License, or
 * (at your option) any later version.
 *
 * CityConnecter is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with CityConnecter.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Copyright 2013-2014 Aun Johnsen
 */
import("util.MinchinWeb", "MetaLib", 6);
	RoadPathFinder <- MetaLib.RoadPathfinder;
	
	

class CityConnecter extends AIController 
{
	constructor()
	{
		::main_instance <- this;
	}
	
	function Init()
	{
	}
	
	function Start();
}

function CityConnecter::TimeStamp()
{
	local date = AIDate.GetCurrentDate();
	local month = AIDate.GetMonth(date);
	local day = AIDate.GetDayOfMonth(date);
	local aMonth = "";
	local aDay = "";
	if (month < 10) aMonth = "0";
	if (day < 10) aDay = "0";
	local ret = "[" + AIDate.GetYear(date) + "-" + aMonth + AIDate.GetMonth(date) + "-" + 
		aDay + AIDate.GetDayOfMonth(date) + "] "; 
	return ret;
}

function CityConnecter::Save()
{
	local table = {};
	
	return table;
}

function CityConnecter::Load(version, data)
{

}

function CityConnecter::SetCompanyName(town)
{
	AILog.Info(TimeStamp() + "Setting Company Name");
	this.Sleep(100);
	local myname = town + " Road Council";
	local i = 0;
	while (!AICompany.SetName(myname)) {
		i++;
		myname = town + " Road Council #"+i;
		if (i > 5) break; // Giving up
	}
	AILog.Info(TimeStamp() + AICompany.GetPresidentName(AICompany.COMPANY_SELF) + 
		" was elected as minister of " + AICompany.GetName(AICompany.COMPANY_SELF));
}


function CityConnecter::Start()
{
	AILog.Info(TimeStamp() + "Starting Script");

	local townlist = AITownList();
	local citylist = AITownList();
	citylist.Valuate(function(id) { if (AITown.IsCity(id)) return 1; return 0; } );
	citylist.KeepValue(1);

	AILog.Info(TimeStamp() + "Time to start work");
	
	AILog.Info(TimeStamp() + "Select a town to start in from a list of " + AITown.GetTownCount() + 
		" ("+ citylist.Count() + " cities)");
	
	
	/* Sort the list by population, highest population first */
	townlist.Valuate(AITown.GetPopulation);
	citylist.Valuate(AITown.GetPopulation);
	
	/* Pick the two town with highest population */
	local townid_a = citylist.Begin();
	/* Build a list of towns around townid_a */
	local instances = 0; /* Find code to identify how many instances of this AI have been loaded */
	instances = AICompany.ResolveCompanyID(AICompany.COMPANY_SELF) - 1;
	if (instances > 0) AILog.Warning(TimeStamp() + "I am instance " + instances + 
		" of this AI, lets start further down the list");
	for (local i = 0; i < instances; i++) {
		townid_a = citylist.Next();
	}
	if (!AIMap.IsValidTile(AICompany.GetCompanyHQ(AICompany.COMPANY_SELF))) this.BuildHQ(townid_a);
	if (AICompany.GetName(AICompany.COMPANY_SELF).find("CityConnecter") == null) {
		this.SetCompanyName(AITown.GetName(townid_a));
	}
	/* Make the list of towns sort by distance to townid_a */
	AILog.Info(TimeStamp() + "Getting distances to " + AITown.GetName(townid_a));
	townlist.Valuate(function(townid_onlist, townid_location) { 
		return AIMap.DistanceManhattan(AITown.GetLocation(townid_onlist), townid_location) } , 
			AITown.GetLocation(townid_a));
	AILog.Info(TimeStamp() + "Sorting list");
		/* Sorting towns based on distance from townid_a */
	townlist.Sort(AIList.SORT_BY_VALUE, AIList.SORT_ASCENDING);
	AILog.Info(TimeStamp() + "List sorted");
	
	local townid_b = townlist.Begin(); // this is self
	townid_b = townlist.Next(); // closest town!
	
	/* Start building */
	this.BuildRoad(townid_a, townid_b);
	
	while (1) {
		AILog.Warning(TimeStamp() + "Political assessment of next project started!");
		townid_b = townlist.Next();
		this.BuildRoad(townid_a, townid_b);
		
		if (townlist.IsEnd()) {
			if (citylist.IsEnd()) townid_a = citylist.Begin();
			else townid_a = citylist.Next();
			townlist.Valuate(function(townid_onlist, townid_location) { 
				return AIMap.DistanceManhattan(AITown.GetLocation(townid_onlist), townid_location) } , 
					AITown.GetLocation(townid_a));
			townlist.Sort(AIList.SORT_BY_VALUE, AIList.SORT_ASCENDING);
			townid_b = townlist.Begin();
			AILog.Warning(TimeStamp() + "We run out of jobs, relocating to " + 
				AITown.GetName(townid_a));
		}
	}
}

function CityConnecter::BuildHQ(town)
{
	// AICompany.BuildCompanyHQ(TileIndex tile)
	AILog.Info(TimeStamp() + "Building Company HQ in "+ AITown.GetName(town));
	
	local Walker = MetaLib.SpiralWalker();
	Walker.Start(AITown.GetLocation(town));
	local HQBuilt = false;
	while (HQBuilt == false) {
		HQBuilt = AICompany.BuildCompanyHQ(Walker.Walk());
	}


	if (AICompany.GetLoanAmount() > 0 ) {
		AILog.Info(TimeStamp() + "Preparing to repay loan");
		local loan = AICompany.GetLoanAmount();
		local interval = AICompany.GetLoanInterval();
		local bankBalance = AICompany.GetBankBalance(AICompany.COMPANY_SELF);
		while (1) {
			loan -= interval;
			AICompany.SetLoanAmount(loan);
			bankBalance = AICompany.GetBankBalance(AICompany.COMPANY_SELF);
			if (bankBalance < interval) break;
		}
		if (AICompany.GetLoanAmount() == 0) {
			AILog.Info(TimeStamp() + "Loan paid completely");
			return; // Loan paid down
		}
	}
}

/*
 * Pathfinds and builds road between two defined points
 */
function CityConnecter::BuildRoad(start, end)
{
	if (!AITown.IsValidTown(start) || !AITown.IsValidTown(end)) {
		AILog.Warning(TimeStamp() + "Either start or target town is invalid, giving up");
		return;
	}
	if (start == end) {
		AILog.Warning(TimeStamp() + "Trying to connect to self, distance is 0");
		return;
	}
	
	local dist = AITile.GetDistanceManhattanToTile(AITown.GetLocation(start), AITown.GetLocation(end))
	
	AIRoad.SetCurrentRoadType(AIRoad.ROADTYPE_ROAD);
	
	/* Print the names of the towns we'll try to connect */
	AILog.Info(TimeStamp() + "Going to connect " + AITown.GetName(start) + "(" + 
		AITown.GetPopulation(start) + ") to " + AITown.GetName(end) + 
		"(" + AITown.GetPopulation(end) + ") with a distance of " + dist + " tiles (manhattan)" );
	local mapDiagonal = AIMap.GetMapSizeX() + AIMap.GetMapSizeY();
	if (dist > (mapDiagonal / 2)) {
		AILog.Warning(TimeStamp() + "Distance too long, giving up. Maxlength: "+(mapDiagonal / 2));
		return;
	}
	/* Tell OpenTTD we want to build normal road (no tram tracks) */
	AIRoad.SetCurrentRoadType(AIRoad.ROADTYPE_ROAD);
	/* Create an instance of the pathfinder */
	local pathfinder = RoadPathFinder();
	/* Setting variables within the pathfinder */
	pathfinder._max_bridge_length = 64;
//	pathfinder._max_tunnel_length = 64;
	
	pathfinder.InitializePath([AITown.GetLocation(end)], [AITown.GetLocation(start)]);
	
	/* Try to find a path */
	local path = false;
	local startDate = AIDate.GetCurrentDate();
	AILog.Info(TimeStamp() + "Starts surveying route");
	while (path == false) {
		path = pathfinder.FindPath(1); /* @param iterations, how many tries before giving up, 
			* -1 = infinity || > 0 */
		this.Sleep(1);
	}
	local endDate = AIDate.GetCurrentDate();
	local dateDiff = endDate - startDate;
	AILog.Info(TimeStamp() + "Survey completed, and took " + dateDiff + " days to complete");
	if (path == null) {
		/* No path was found */
		AILog.Error(TimeStamp() + "pathfinder.FindPath return NULL");
	}
	
	/* If a path was found, build a road over it */
	AILog.Info(TimeStamp() + "Path found, building road between " + AITown.GetName(start) + 
		" and " + AITown.GetName(end));
	local bankBalance = AICompany.GetBankBalance(AICompany.COMPANY_SELF);
	local maxLoan = AICompany.GetMaxLoanAmount();
	local loan = AICompany.GetLoanAmount();
	local toLoan = maxLoan - loan;
	if (toLoan > 0) {
		AILog.Info(TimeStamp() + "Loaning £" + toLoan);
		AICompany.SetLoanAmount(maxLoan);
		this.Sleep(3);
	}
	if (AICompany.GetBankBalance(AICompany.COMPANY_SELF) > bankBalance) AILog.Info(TimeStamp() + 
		"Bank Balance increased for construction project");
	if (AICompany.GetBankBalance(AICompany.COMPANY_SELF) < 1) {
		AILog.Error(TimeStamp() + "We are broke and no longer able to operate");
		/* Make a code to kill AI so it can be reloaded */
		return;
	}
	AILog.Info(TimeStamp() + "The budget limit for this project is: £" + 
		AICompany.GetBankBalance(AICompany.COMPANY_SELF) + ".");
	local startBalance = AICompany.GetBankBalance(AICompany.COMPANY_SELF);
	while (path != null) {
		local par = path.GetParent();
		if (par != null) {
			local last_node = path.GetTile();
			if (AIMap.DistanceManhattan(path.GetTile(), par.GetTile()) == 1) {
				if (!AIRoad.BuildRoad(path.GetTile(), par.GetTile())) {
					/* An error occured while building a piece of road. TODO: handle it.
					 * Note that this can also be the case of the road was already build */
				}
			} else {
				/* Build a bridge or tunnel */
//				AILog.Info(TimeStamp() + "We need to build a bridge or tunnel");
				if (!AIBridge.IsBridgeTile(path.GetTile()) && !AITunnel.IsTunnelTile(path.GetTile())) {
					/* If it was a road tile, demolish it first. Do this to work 
					 * around expended roadbits */
					if (AIRoad.IsRoadTile(path.GetTile())) AITile.DemolishTile(path.GetTile());
					if (AITunnel.GetOtherTunnelEnd(path.GetTile()) == par.GetTile()) {
						if (!AITunnel.BuildTunnel(AIVehicle.VT_ROAD, path.GetTile())) {
							/* An error occured while building a tunnel. TODO: handle it */
//							AILog.Warning(TimeStamp() + "Error building tunnel");
						}
					} else {
						local bridge_list = AIBridgeList_Length(AIMap.DistanceManhattan(path.GetTile(), 
							par.GetTile()) + 1);
						bridge_list.Valuate(AIBridge.GetPrice, AIMap.DistanceManhattan(path.GetTile(), 
							par.GetTile()));
						bridge_list.Sort(AIList.SORT_BY_VALUE, AIList.SORT_ASCENDING);
						if (!AIBridge.BuildBridge(AIVehicle.VT_ROAD, bridge_list.Begin(), path.GetTile(), 
							par.GetTile())) {
							/* An error occured while building a bridge. TODO: handle it */
//							AILog.Warning(TimeStamp() + "Error building bridge");
						}
					}
				}
			}
		}
		path = par;
	}
	local spent = startBalance - AICompany.GetBankBalance(AICompany.COMPANY_SELF);
	AILog.Info(TimeStamp() + "Project completed! Total spent: £" + spent);
		/* Repay loan as best we can to make us last longer */
	if (AICompany.GetLoanAmount() > 0 ) {
		AILog.Info(TimeStamp() + "Preparing to repay loan");
		local loan = AICompany.GetLoanAmount();
		local interval = AICompany.GetLoanInterval();
		local bankBalance = AICompany.GetBankBalance(AICompany.COMPANY_SELF);
		while (1) {
			loan -= interval;
			AICompany.SetLoanAmount(loan);
			bankBalance = AICompany.GetBankBalance(AICompany.COMPANY_SELF);
			if (bankBalance < interval) break;
		}
		if (AICompany.GetLoanAmount() == 0) {
			AILog.Info(TimeStamp() + "Loan paid completely");
			return; // Loan paid down
		}
	}
}
