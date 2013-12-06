#ifndef __PIDFILE_H
#define __PIDFILE_H

#include <boost/interprocess/sync/file_lock.hpp>
#include <boost/filesystem.hpp>
#include <fstream>
#include "log.h"

using namespace boost::interprocess;

namespace common {

class Pidfile
{
public:
    Pidfile( const char *filePath )
    : filePath_( filePath )
    {
        bool fileExists = boost::filesystem::exists( filePath );

        file_.open( filePath );

        file_lock f_lock( filePath );
        if ( !f_lock.try_lock() )
        {
            PLOG( "can't exclusively lock pid_file=" << filePath_ );
            exit( 1 );
        }

		f_lock_.swap( f_lock );

        file_ << getpid();
        file_.flush();

        afterFail_ = fileExists;
        if ( afterFail_ )
        {
            PLOG( "previous process terminated abnormally" );
        }
    }

    ~Pidfile()
    {
        try
        {
            f_lock_.unlock();
            file_.close();
            boost::filesystem::remove( filePath_ );
        }
        catch(...)
        {
            PLOG( "exception in ~Pidfile()" );
        }
    }

    bool AfterFail() const { return afterFail_; }

private:
    bool afterFail_;
    std::string filePath_;
    file_lock f_lock_;
    std::ofstream file_;
};

} // namespace common

#endif
