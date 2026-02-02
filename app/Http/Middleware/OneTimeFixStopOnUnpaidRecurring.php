<?php

namespace App\Http\Middleware;

use Closure;
use App\Models\Company;
use Illuminate\Support\Facades\File;

class OneTimeFixStopOnUnpaidRecurring
{
    public function handle($request, Closure $next)
    {
        $flagDir = storage_path('app/flags');
        $flagFile = $flagDir . DIRECTORY_SEPARATOR . 'stop_on_unpaid_recurring_fixed';

        if (! File::exists($flagFile)) {
            try {
                if (! File::exists($flagDir)) {
                    File::makeDirectory($flagDir, 0755, true);
                }

                Company::query()
                    ->where('stop_on_unpaid_recurring', 1)
                    ->update(['stop_on_unpaid_recurring' => 0]);

                File::put($flagFile, (string) time());
            } catch (\Throwable $e) {
                
                if (function_exists('nlog')) {
                    nlog('OneTimeFixStopOnUnpaidRecurring failed: ' . $e->getMessage());
                }
            }
        }

        return $next($request);
    }
}
