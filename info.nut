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

 class CityConnecter extends AIInfo {
        function GetAuthor()      { return "Aun Johnsen"; }
        function GetName()        { return "CityConnecter"; }
        function GetVersion()     { return 1; }
		function MinVersionToLoad() { return 1; }
        function GetDescription() { return "Regional Road Construction Council"; }
        function GetAPIVersion()  { return "1.3"; }
        function CreateInstance() { return "CityConnecter"; }
        function GetShortName()   { return "RRCC"; }
        function GetDate()        { return "2014-01-25"; }
}

RegisterAI(CityConnecter());