/*
===========================================================================

This software is licensed under the Apache 2 license, quoted below.

Copyright (C) 2013 Andrey Budnik <budnik27@gmail.com>

Licensed under the Apache License, Version 2.0 (the "License"); you may not
use this file except in compliance with the License. You may obtain a copy of
the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
License for the specific language governing permissions and limitations under
the License.

===========================================================================
*/

#ifndef __WORKER_COMMAND_H
#define __WORKER_COMMAND_H

#include "common/log.h"
#include "command.h"

namespace master {

class StopTaskCommand : public Command
{
public:
    StopTaskCommand()
    : Command( "stop_task" )
    {}

private:
    virtual void OnCompletion( int errCode, const std::string &hostIP )
    {
        PLOG( "Stopping task on worker " << hostIP << ", errCode=" << errCode );
    }

    virtual int GetRepeatDelay() const
    {
        return REPEAT_DELAY;
    }

private:
    const static int REPEAT_DELAY = 60; // 60 sec
};

class StopAllJobsCommand : public Command
{
public:
    StopAllJobsCommand()
    : Command( "stop_all" )
    {}

private:
    virtual void OnCompletion( int errCode, const std::string &hostIP )
    {
        PLOG( "Stopping all jobs on worker " << hostIP << ", errCode=" << errCode );
    }

    virtual int GetRepeatDelay() const
    {
        return REPEAT_DELAY;
    }

private:
    const static int REPEAT_DELAY = 60; // 60 sec
};


class StopPreviousJobsCommand : public Command
{
public:
    StopPreviousJobsCommand()
    : Command( "stop_prev" )
    {}

private:
    virtual void OnCompletion( int errCode, const std::string &hostIP )
    {
        PLOG( "Stopping previous jobs on worker " << hostIP << ", errCode=" << errCode );
    }

    virtual int GetRepeatDelay() const
    {
        return REPEAT_DELAY;
    }

private:
    const static int REPEAT_DELAY = 60; // 60 sec
};

} // namespace master

#endif
